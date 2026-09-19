#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

let guidelinesRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let contractBegin = "<!-- BEGIN THATFACTORY CODE REVIEW CONTRACT v2 -->"
let contractEnd = "<!-- END THATFACTORY CODE REVIEW CONTRACT v2 -->"
let documentationContractBegin = "<!-- BEGIN THATFACTORY DOCUMENTATION MAINTENANCE CONTRACT v1 -->"
let documentationContractEnd = "<!-- END THATFACTORY DOCUMENTATION MAINTENANCE CONTRACT v1 -->"
let externalDependencyContractBegin = "<!-- BEGIN THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1 -->"
let externalDependencyContractEnd = "<!-- END THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1 -->"
let observabilityContractBegin = "<!-- BEGIN THATFACTORY RUNTIME OBSERVABILITY CONTRACT v1 -->"
let observabilityContractEnd = "<!-- END THATFACTORY RUNTIME OBSERVABILITY CONTRACT v1 -->"
let markdownLinkPattern = #"\[[^\]]+\]\(([^)]+)\)"#
let swiftFormatGuide = "AgentGuidelines/Guidelines/Swift/SwiftFormat.md"
let strictFormatCommandPattern =
    #"(?m)^[ \t]*(?:-\s+)?(?:run:\s*)?(?:\./)?AgentGuidelines/Scripts/swift_format\.sh\s+lint-strict(?=\s|\\|$)"#
let mutatingFormatCommandPattern =
    #"(?m)^[ \t]*(?:-\s+)?(?:run:\s*)?(?:\./)?AgentGuidelines/Scripts/swift_format\.sh\s+format(?:-and-lint)?(?=\s|\\|$)"#
let generatedAttributePattern = #"(?m)^\s*AgentGuidelines/\*\*\s+linguist-generated\s*$"#
let readmeLicenseHeadingPattern = #"(?im)^[ \t]{0,3}#{1,6}[ \t]+license[ \t]*#*[ \t]*$"#
let readmeSetextUnderlinePattern = #"^[ \t]{0,3}(?:=+|-+)[ \t]*$"#
let readmeLicenseParagraphPattern =
    #"(?i)^.+?\s+is\s+available\s+under\s+the\s+.+?\s+license\.\s+See\s+\[LICENSE\]\((?:\./)?LICENSE\)\.$"#

/// Parsed consumer-validation command-line values.
struct Arguments {
    var consumerRoot: String?
    var requireSwiftFormat = false
}

/// Returns all regular-expression matches in a string.
func matches(_ pattern: String, in value: String) -> [NSTextCheckingResult] {
    guard let expression = try? NSRegularExpression(pattern: pattern) else {
        return []
    }
    return expression.matches(in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
}

/// Returns one capture from a regular-expression match.
func capture(_ index: Int, from match: NSTextCheckingResult, in value: String) -> String? {
    let range = match.range(at: index)
    guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else {
        return nil
    }
    return String(value[swiftRange])
}

/// Reads UTF-8 text and records a labeled error on failure.
func readText(_ url: URL, errors: inout [String], label: String) -> String? {
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        errors.append("\(label): cannot read \(url.path): \(error.localizedDescription)")
        return nil
    }
}

/// Extracts one uniquely marked contract block.
func extractMarkedBlock(
    _ contents: String,
    begin: String,
    end: String,
    errors: inout [String],
    label: String
) -> String? {
    guard contents.components(separatedBy: begin).count - 1 == 1,
        contents.components(separatedBy: end).count - 1 == 1,
        let start = contents.range(of: begin),
        let finish = contents.range(of: end, range: start.upperBound..<contents.endIndex)
    else {
        errors.append("\(label): expected exactly one '\(begin)' and '\(end)'")
        return nil
    }
    return String(contents[start.lowerBound..<finish.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Validates that a path is a symlink to an expected target.
func validateSymlink(_ url: URL, expected: URL, errors: inout [String], label: String) {
    let fileManager = FileManager.default
    do {
        _ = try fileManager.destinationOfSymbolicLink(atPath: url.path)
    } catch {
        errors.append("\(label): \(url.path) must be a symlink to \(expected.path)")
        return
    }
    guard fileManager.fileExists(atPath: url.path) else {
        errors.append("\(label): \(url.path) is a broken symlink")
        return
    }
    let actual = url.standardizedFileURL.resolvingSymlinksInPath()
    let resolvedExpected = expected.standardizedFileURL.resolvingSymlinksInPath()
    if actual.path != resolvedExpected.path {
        errors.append("\(label): \(url.path) resolves to \(actual.path), expected \(resolvedExpected.path)")
    }
}

/// Validates local Markdown links from the consumer root instructions.
func validateAgentLinks(agentsURL: URL, contents: String, errors: inout [String]) {
    for match in matches(markdownLinkPattern, in: contents) {
        guard var target = capture(1, from: match, in: contents) else {
            continue
        }
        target = target.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(
            in: CharacterSet(charactersIn: "<>"))
        target = target.components(separatedBy: "#").first ?? target
        if target.isEmpty || ["#", "http://", "https://", "mailto:"].contains(where: target.hasPrefix) {
            continue
        }
        let resolved = agentsURL.deletingLastPathComponent().appendingPathComponent(target).standardizedFileURL
        if !FileManager.default.fileExists(atPath: resolved.path) {
            errors.append("AGENTS.md: missing local link target '\(target)'")
        }
    }
}

/// Returns whether root instructions link the shared Swift-format guide.
func adoptsSwiftFormat(_ contents: String) -> Bool {
    for match in matches(markdownLinkPattern, in: contents) {
        guard var target = capture(1, from: match, in: contents) else {
            continue
        }
        target = target.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(
            in: CharacterSet(charactersIn: "<>"))
        target = target.components(separatedBy: "#").first ?? target
        if target.hasSuffix(swiftFormatGuide) {
            return true
        }
    }
    return false
}

/// Returns complete shell invocations matching a command pattern.
func shellInvocations(_ contents: String, pattern: String) -> [String] {
    let lines = contents.components(separatedBy: .newlines)
    var invocations: [String] = []
    var index = 0
    while index < lines.count {
        let line = lines[index]
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") || matches(pattern, in: line).isEmpty {
            index += 1
            continue
        }
        var invocation = [line]
        while invocation.last?.trimmingCharacters(in: .whitespaces).hasSuffix("\\") == true,
            index + 1 < lines.count
        {
            index += 1
            invocation.append(lines[index])
        }
        invocations.append(invocation.joined(separator: "\n"))
        index += 1
    }
    return invocations
}

/// Returns direct files with one of the requested extensions.
func files(in directory: URL, extensions: Set<String>) -> [URL] {
    guard
        let values = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
    else {
        return []
    }
    return values.filter { extensions.contains($0.pathExtension.lowercased()) }.sorted { $0.path < $1.path }
}

/// Returns a Markdown fence marker and run length when a line can open or close a fenced code block.
func markdownFence(in line: String) -> (character: Character, length: Int, suffix: Substring)? {
    let indentation = line.prefix(while: { $0 == " " }).count
    let content = line.dropFirst(indentation)
    guard indentation <= 3, let character = content.first, character == "`" || character == "~"
    else {
        return nil
    }
    let length = content.prefix(while: { $0 == character }).count
    guard length >= 3 else { return nil }
    return (character, length, content.dropFirst(length))
}

/// Returns whether a line is eligible to be the title of a Setext License heading.
func isSetextLicenseTitle(_ line: String) -> Bool {
    let indentation = line.prefix(while: { $0 == " " }).count
    guard indentation <= 3 else { return false }
    return line.dropFirst(indentation).trimmingCharacters(in: .whitespaces)
        .localizedCaseInsensitiveCompare("License") == .orderedSame
}

/// Validates package README license content without inspecting vendored or non-package documentation.
func validatePackageReadme(consumerRoot: URL, errors: inout [String]) {
    guard FileManager.default.fileExists(atPath: consumerRoot.appendingPathComponent("Package.swift").path) else {
        return
    }
    let readmeURL = consumerRoot.appendingPathComponent("README.md")
    guard FileManager.default.fileExists(atPath: readmeURL.path),
        let contents = readText(readmeURL, errors: &errors, label: "consumer package README")
    else {
        return
    }
    var outsideFences: [String] = []
    var activeFence: (character: Character, length: Int)?
    for line in contents.components(separatedBy: .newlines) {
        if let currentFence = activeFence {
            if let marker = markdownFence(in: line), marker.character == currentFence.character,
                marker.length >= currentFence.length,
                marker.suffix.trimmingCharacters(in: .whitespaces).isEmpty
            {
                activeFence = nil
            }
            outsideFences.append("")
        } else if let marker = markdownFence(in: line),
            marker.character == "~" || !marker.suffix.contains("`")
        {
            activeFence = (marker.character, marker.length)
            outsideFences.append("")
        } else {
            outsideFences.append(line)
        }
    }
    let governedContents = outsideFences.joined(separator: "\n")
    let lines = governedContents.components(separatedBy: .newlines)
    let hasSetextLicenseHeading = lines.indices.dropLast().contains { index in
        isSetextLicenseTitle(lines[index]) && !matches(readmeSetextUnderlinePattern, in: lines[index + 1]).isEmpty
    }
    if !matches(readmeLicenseHeadingPattern, in: governedContents).isEmpty || hasSetextLicenseHeading {
        errors.append("consumer package README: README.md must not contain a dedicated License heading")
    }
    let paragraphs = governedContents.components(separatedBy: "\n\n").map {
        $0.split(whereSeparator: \.isNewline).joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if paragraphs.contains(where: { !matches(readmeLicenseParagraphPattern, in: $0).isEmpty }) {
        errors.append("consumer package README: README.md must not contain a standalone license-description paragraph")
    }
}

/// Validates non-mutating Swift-format CI integration.
func validateSwiftFormatCI(consumerRoot: URL, errors: inout [String]) {
    let workflowsRoot = consumerRoot.appendingPathComponent(".github/workflows")
    let workflows = files(in: workflowsRoot, extensions: ["yml", "yaml"])
    if workflows.isEmpty {
        errors.append("consumer Swift format CI: no GitHub Actions workflows found under .github/workflows")
        return
    }
    var strictWorkflows: [(URL, String, [String])] = []
    for workflow in workflows {
        let relative = workflow.path.replacingOccurrences(of: consumerRoot.path + "/", with: "")
        guard let contents = readText(workflow, errors: &errors, label: "consumer Swift format CI workflow \(relative)")
        else {
            continue
        }
        if !shellInvocations(contents, pattern: mutatingFormatCommandPattern).isEmpty {
            errors.append(
                "consumer Swift format CI: \(relative) must not mutate sources with format or format-and-lint")
        }
        let invocations = shellInvocations(contents, pattern: strictFormatCommandPattern)
        if !invocations.isEmpty {
            strictWorkflows.append((workflow, contents, invocations))
        }
    }
    if strictWorkflows.isEmpty {
        errors.append(
            "consumer Swift format CI: missing 'AgentGuidelines/Scripts/swift_format.sh lint-strict' invocation")
        return
    }
    if !strictWorkflows.contains(where: { !matches(#"(?m)^\s*pull_request\s*:"#, in: $0.1).isEmpty }) {
        errors.append("consumer Swift format CI: lint-strict does not run for pull requests")
    }
    let pushPattern = #"(?m)^\s*push\s*:"#
    let mainPattern = #"(?m)^\s*-?\s*main\s*$|branches\s*:\s*\[[^]]*\bmain\b"#
    if !strictWorkflows.contains(where: {
        !matches(pushPattern, in: $0.1).isEmpty && !matches(mainPattern, in: $0.1).isEmpty
    }) {
        errors.append("consumer Swift format CI: lint-strict does not run for pushes to main")
    }
    if FileManager.default.fileExists(atPath: consumerRoot.appendingPathComponent("Package.swift").path) {
        var requiredPaths = ["Package.swift"]
        for name in ["Sources", "Tests"] {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(
                atPath: consumerRoot.appendingPathComponent(name).path,
                isDirectory: &isDirectory
            ), isDirectory.boolValue {
                requiredPaths.append(name)
            }
        }
        let combined = strictWorkflows.flatMap(\.2).joined(separator: "\n")
        for path in requiredPaths {
            let escaped = NSRegularExpression.escapedPattern(for: path)
            if matches("(?<![\\w./-])\(escaped)(?![\\w./-])", in: combined).isEmpty {
                errors.append("consumer Swift format CI: package lint-strict scope is missing '\(path)'")
            }
        }
    }
}

/// Validates a consumer repository's checked-in shared-guideline integration.
func validateConsumerSetup(
    errors: inout [String],
    consumerRoot: URL,
    activeGuidelinesRoot: URL = guidelinesRoot,
    requireSwiftFormat: Bool = false
) {
    let consumerRoot = consumerRoot.standardizedFileURL.resolvingSymlinksInPath()
    let activeGuidelinesRoot = activeGuidelinesRoot.standardizedFileURL.resolvingSymlinksInPath()
    let subtree = consumerRoot.appendingPathComponent("AgentGuidelines")
    if !FileManager.default.fileExists(atPath: subtree.path) {
        errors.append("consumer root: missing \(subtree.path)")
    } else if subtree.standardizedFileURL.resolvingSymlinksInPath().path != activeGuidelinesRoot.path {
        errors.append(
            "consumer root: \(subtree.path) resolves to "
                + "\(subtree.standardizedFileURL.resolvingSymlinksInPath().path), expected the active guidelines at "
                + activeGuidelinesRoot.path
        )
    }
    let versionURL = activeGuidelinesRoot.appendingPathComponent("VERSION")
    if let version = readText(versionURL, errors: &errors, label: "AgentGuidelines/VERSION"),
        version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
        errors.append("AgentGuidelines/VERSION: version is empty")
    }
    let templateURL = activeGuidelinesRoot.appendingPathComponent("Templates/AGENTS.md")
    let agentsURL = consumerRoot.appendingPathComponent("AGENTS.md")
    let template = readText(templateURL, errors: &errors, label: "AgentGuidelines template")
    let agents = readText(agentsURL, errors: &errors, label: "consumer AGENTS.md")
    var swiftFormatAdopted = requireSwiftFormat
    if let template, let agents {
        let contracts = [
            (contractBegin, contractEnd, "code-review"),
            (documentationContractBegin, documentationContractEnd, "documentation-maintenance"),
            (externalDependencyContractBegin, externalDependencyContractEnd, "external-dependency"),
            (observabilityContractBegin, observabilityContractEnd, "runtime-observability"),
        ]
        for (begin, end, name) in contracts {
            let expected = extractMarkedBlock(
                template, begin: begin, end: end, errors: &errors, label: "AgentGuidelines template")
            let actual = extractMarkedBlock(
                agents, begin: begin, end: end, errors: &errors, label: "consumer AGENTS.md")
            if let expected, let actual, expected != actual {
                errors.append("consumer AGENTS.md: \(name) contract does not match AgentGuidelines/Templates/AGENTS.md")
            }
        }
        for value in ["## Codex review scope", "AgentGuidelines/**", "exact tagged-tree provenance", ".gitattributes"]
        where !agents.contains(value) {
            errors.append("consumer AGENTS.md: missing Codex review scope value '\(value)'")
        }
        validateAgentLinks(agentsURL: agentsURL, contents: agents, errors: &errors)
        swiftFormatAdopted = swiftFormatAdopted || adoptsSwiftFormat(agents)
    }
    let attributesURL = consumerRoot.appendingPathComponent(".gitattributes")
    if let attributes = readText(attributesURL, errors: &errors, label: "consumer .gitattributes"),
        matches(generatedAttributePattern, in: attributes).isEmpty
    {
        errors.append("consumer .gitattributes: missing exact 'AgentGuidelines/** linguist-generated' rule")
    }
    validateSymlink(
        consumerRoot.appendingPathComponent(".agents/skills/agent-guidelines-audit"),
        expected: activeGuidelinesRoot.appendingPathComponent(".agents/skills/agent-guidelines-audit"),
        errors: &errors,
        label: "consumer audit skill"
    )
    let formatterLinks = [
        ".swift-format": activeGuidelinesRoot.appendingPathComponent("Configurations/Swift/.swift-format"),
        ".editorconfig": activeGuidelinesRoot.appendingPathComponent("Configurations/Swift/.editorconfig"),
    ]
    for (name, expected) in formatterLinks {
        let path = consumerRoot.appendingPathComponent(name)
        if swiftFormatAdopted || (try? FileManager.default.destinationOfSymbolicLink(atPath: path.path)) != nil {
            validateSymlink(path, expected: expected, errors: &errors, label: "consumer \(name)")
        }
    }
    if swiftFormatAdopted {
        validateSwiftFormatCI(consumerRoot: consumerRoot, errors: &errors)
    }
    validatePackageReadme(consumerRoot: consumerRoot, errors: &errors)
}

/// Parses command-line arguments.
func parseArguments(_ values: [String]) throws -> Arguments {
    var arguments = Arguments()
    var index = 0
    while index < values.count {
        let value = values[index]
        switch value {
        case "--help":
            print("Usage: validate_consumer_setup.swift [--consumer-root <path>] [--require-swift-format]")
            exit(0)
        case "--require-swift-format":
            arguments.requireSwiftFormat = true
            index += 1
        case "--consumer-root":
            guard index + 1 < values.count else {
                throw NSError(
                    domain: "ConsumerSetup", code: 2,
                    userInfo: [
                        NSLocalizedDescriptionKey: "missing value for --consumer-root"
                    ])
            }
            arguments.consumerRoot = values[index + 1]
            index += 2
        default:
            throw NSError(
                domain: "ConsumerSetup", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "unknown argument: \(value)"
                ])
        }
    }
    return arguments
}

/// Writes text to standard error.
func writeError(_ value: String) {
    FileHandle.standardError.write(Data((value + "\n").utf8))
}

/// Runs consumer integration validation.
func main() -> Int32 {
    do {
        let arguments = try parseArguments(Array(CommandLine.arguments.dropFirst()))
        let root: URL
        if let consumerRoot = arguments.consumerRoot {
            root = URL(fileURLWithPath: consumerRoot)
        } else {
            guard guidelinesRoot.lastPathComponent == "AgentGuidelines" else {
                print(
                    "Consumer setup validation failed:\n"
                        + "- --consumer-root is required when this checkout is not installed as an AgentGuidelines subtree"
                )
                return 1
            }
            root = guidelinesRoot.deletingLastPathComponent()
        }
        var errors: [String] = []
        validateConsumerSetup(
            errors: &errors,
            consumerRoot: root,
            requireSwiftFormat: arguments.requireSwiftFormat
        )
        if !errors.isEmpty {
            print("Consumer setup validation failed:")
            for error in errors { print("- \(error)") }
            return 1
        }
        let version = try String(
            contentsOf: guidelinesRoot.appendingPathComponent("VERSION"),
            encoding: .utf8
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        print("Validated consumer setup for agent-guidelines \(version).")
        return 0
    } catch {
        writeError("Consumer setup validation failed: \(error.localizedDescription)")
        return 2
    }
}

exit(main())
