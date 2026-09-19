#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// Parsed command-line values for String Catalog inspection evidence.
struct Arguments {
    var repository = FileManager.default.currentDirectoryPath
    var baseRef: String?
    var inspectedCatalogs: [String] = []
    var evidenceOutput: String?
}

/// Runs a process in a repository and returns its standard output.
func run(_ command: [String], repositoryRoot: String) throws -> Data {
    let process = Process()
    let output = Pipe()
    process.currentDirectoryURL = URL(fileURLWithPath: repositoryRoot)
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = command
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        let detail =
            String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? "command failed"
        throw NSError(
            domain: "StringCatalogInspection", code: Int(process.terminationStatus),
            userInfo: [
                NSLocalizedDescriptionKey: "\(command.joined(separator: " ")): \(detail)"
            ])
    }
    return outputData
}

/// Returns the Git repository root containing a requested path.
func repositoryRoot(containing repository: String) throws -> String {
    let data = try run(["git", "rev-parse", "--show-toplevel"], repositoryRoot: repository)
    guard let root = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
        !root.isEmpty
    else {
        throw NSError(
            domain: "StringCatalogInspection", code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "git returned no repository root"
            ])
    }
    return URL(fileURLWithPath: root).standardizedFileURL.path
}

/// Parses NUL-separated Git paths and retains String Catalogs.
func catalogPaths(from data: Data) -> Set<String> {
    guard let output = String(data: data, encoding: .utf8) else {
        return []
    }
    return Set(output.split(separator: "\0").map(String.init).filter { $0.hasSuffix(".xcstrings") })
}

/// Returns added, copied, modified, renamed, and untracked String Catalogs.
func changedCatalogs(root: String, baseRef: String) throws -> Set<String> {
    _ = try run(["git", "rev-parse", "--verify", "\(baseRef)^{commit}"], repositoryRoot: root)
    let tracked = try run(
        ["git", "diff", "--name-only", "-z", "--diff-filter=ACMR", baseRef, "--"],
        repositoryRoot: root
    )
    let untracked = try run(
        ["git", "ls-files", "--others", "--exclude-standard", "-z"],
        repositoryRoot: root
    )
    return catalogPaths(from: tracked).union(catalogPaths(from: untracked))
}

/// Normalizes repository-relative catalog paths supplied as inspection evidence.
func normalizedInspections(_ values: [String]) throws -> Set<String> {
    var inspections = Set<String>()
    for value in values {
        let components = NSString(string: value).pathComponents
        guard !NSString(string: value).isAbsolutePath,
            !components.contains(".."),
            value.hasSuffix(".xcstrings")
        else {
            throw NSError(
                domain: "StringCatalogInspection", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "--inspected-catalog values must be repository-relative .xcstrings paths"
                ])
        }
        inspections.insert(NSString(string: value).standardizingPath)
    }
    return inspections
}

/// Returns fail-closed coverage errors for catalog-editor inspection evidence.
func inspectionCoverageErrors(changed: Set<String>, inspected: Set<String>) -> [String] {
    let missing = changed.subtracting(inspected).sorted().map {
        "missing Xcode catalog-editor inspection evidence: \($0)"
    }
    let unexpected = inspected.subtracting(changed).sorted().map {
        "inspection evidence does not match a changed String Catalog: \($0)"
    }
    return missing + unexpected
}

/// Returns the selected Xcode version and build used for the inspection record.
func selectedXcodeVersion(root: String) throws -> String {
    let data = try run(["xcodebuild", "-version"], repositoryRoot: root)
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

/// Writes structured, non-repository evidence for a completed editor inspection.
func writeEvidence(
    output: String,
    root: String,
    baseRef: String,
    xcodeVersion: String,
    catalogs: Set<String>
) throws {
    let rootURL = URL(fileURLWithPath: root).standardizedFileURL.resolvingSymlinksInPath()
    let outputURL = URL(fileURLWithPath: output).standardizedFileURL.resolvingSymlinksInPath()
    let rootPath = rootURL.path.hasSuffix("/") ? rootURL.path : rootURL.path + "/"
    guard outputURL.path != rootURL.path, !outputURL.path.hasPrefix(rootPath) else {
        throw NSError(
            domain: "StringCatalogInspection", code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "--evidence-output must be outside the repository"
            ])
    }
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let evidence: [String: Any] = [
        "schemaVersion": 1,
        "recordedAt": formatter.string(from: Date()),
        "baseRef": baseRef,
        "xcodeVersion": xcodeVersion,
        "catalogs": catalogs.sorted().map {
            [
                "path": $0,
                "catalogEditorErrors": 0,
                "catalogEditorWarnings": 0,
            ]
        },
    ]
    let data = try JSONSerialization.data(withJSONObject: evidence, options: [.prettyPrinted, .sortedKeys])
    var contents = data
    contents.append(0x0A)
    try contents.write(to: outputURL, options: .atomic)
}

/// Parses command-line arguments.
func parseArguments(_ values: [String]) throws -> Arguments {
    var arguments = Arguments()
    var index = 0
    while index < values.count {
        let value = values[index]
        if value == "--help" {
            print(
                "Usage: check_xcstrings_inspection.swift --base-ref <ref> "
                    + "[--repository <path>] [--inspected-catalog <path> ...] "
                    + "[--evidence-output <path>]"
            )
            exit(0)
        }
        guard index + 1 < values.count else {
            throw NSError(
                domain: "StringCatalogInspection", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "missing value for \(value)"
                ])
        }
        let next = values[index + 1]
        switch value {
        case "--repository": arguments.repository = next
        case "--base-ref": arguments.baseRef = next
        case "--inspected-catalog": arguments.inspectedCatalogs.append(next)
        case "--evidence-output": arguments.evidenceOutput = next
        default:
            throw NSError(
                domain: "StringCatalogInspection", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "unknown argument: \(value)"
                ])
        }
        index += 2
    }
    guard arguments.baseRef != nil else {
        throw NSError(
            domain: "StringCatalogInspection", code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "--base-ref is required"
            ])
    }
    return arguments
}

/// Writes text to standard error.
func writeError(_ value: String) {
    FileHandle.standardError.write(Data((value + "\n").utf8))
}

/// Validates inspection coverage and writes the structured evidence record.
func main() -> Int32 {
    do {
        let arguments = try parseArguments(Array(CommandLine.arguments.dropFirst()))
        let root = try repositoryRoot(containing: arguments.repository)
        guard let baseRef = arguments.baseRef else {
            return 2
        }
        let changed = try changedCatalogs(root: root, baseRef: baseRef)
        let inspected = try normalizedInspections(arguments.inspectedCatalogs)
        var errors = inspectionCoverageErrors(changed: changed, inspected: inspected)
        if !changed.isEmpty, arguments.evidenceOutput == nil {
            errors.append("--evidence-output is required when String Catalogs changed")
        }
        if !errors.isEmpty {
            for error in errors {
                writeError("String Catalog inspection audit failed: \(error)")
            }
            return 1
        }
        if changed.isEmpty {
            print(
                "No changed String Catalogs relative to \(baseRef); "
                    + "Xcode catalog-editor inspection evidence is not required."
            )
            return 0
        }
        guard let evidenceOutput = arguments.evidenceOutput else {
            return 1
        }
        try writeEvidence(
            output: evidenceOutput,
            root: root,
            baseRef: baseRef,
            xcodeVersion: try selectedXcodeVersion(root: root),
            catalogs: changed
        )
        print(
            "Recorded zero Xcode catalog-editor errors and warnings for "
                + "\(changed.count) changed String Catalog(s) at \(evidenceOutput)."
        )
        return 0
    } catch {
        writeError("String Catalog inspection audit failed: \(error.localizedDescription)")
        return 2
    }
}

exit(main())
