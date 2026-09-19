#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

struct CommandResult {
    let status: Int32
    let output: String

    var succeeded: Bool { status == 0 }
}

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

let repositoryRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let fileManager = FileManager.default

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    guard condition() else { throw TestFailure(description: message) }
}

func run(_ arguments: [String], directory: URL = repositoryRoot) throws -> CommandResult {
    let process = Process()
    let output = Pipe()
    process.currentDirectoryURL = directory
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return CommandResult(status: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
}

func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
    let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? fileManager.removeItem(at: directory) }
    try body(directory)
}

func write(_ value: String, to url: URL) throws {
    try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try value.write(to: url, atomically: true, encoding: .utf8)
}

func script(_ path: String) -> String {
    repositoryRoot.appendingPathComponent(path).path
}

func copyRepositoryFixture(to destination: URL) throws {
    try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
    let children = try fileManager.contentsOfDirectory(at: repositoryRoot, includingPropertiesForKeys: nil)
    for child in children where ![".git", ".build"].contains(child.lastPathComponent) {
        try fileManager.copyItem(at: child, to: destination.appendingPathComponent(child.lastPathComponent))
    }
}

func git(_ arguments: String..., in directory: URL) throws {
    let result = try run(["git"] + arguments, directory: directory)
    try require(result.succeeded, "git \(arguments.joined(separator: " ")) failed: \(result.output)")
}

func initializeRepository(at root: URL) throws {
    try git("init", in: root)
    try git("config", "user.email", "agent@example.com", in: root)
    try git("config", "user.name", "Agent", in: root)
}

func createConsumerFixture(at root: URL, isPackage: Bool, readme: String? = nil) throws {
    try fileManager.createSymbolicLink(
        at: root.appendingPathComponent("AgentGuidelines"), withDestinationURL: repositoryRoot)
    try fileManager.copyItem(
        at: repositoryRoot.appendingPathComponent("Templates/AGENTS.md"),
        to: root.appendingPathComponent("AGENTS.md"))
    try write("AgentGuidelines/** linguist-generated\n", to: root.appendingPathComponent(".gitattributes"))
    let skillParent = root.appendingPathComponent(".agents/skills")
    try fileManager.createDirectory(at: skillParent, withIntermediateDirectories: true)
    try fileManager.createSymbolicLink(
        at: skillParent.appendingPathComponent("agent-guidelines-audit"),
        withDestinationURL: repositoryRoot.appendingPathComponent(".agents/skills/agent-guidelines-audit")
    )
    try fileManager.createSymbolicLink(
        at: root.appendingPathComponent(".swift-format"),
        withDestinationURL: repositoryRoot.appendingPathComponent("Configurations/Swift/.swift-format"))
    try fileManager.createSymbolicLink(
        at: root.appendingPathComponent(".editorconfig"),
        withDestinationURL: repositoryRoot.appendingPathComponent("Configurations/Swift/.editorconfig"))
    try write(
        """
        name: CI
        on:
          pull_request:
          push:
            branches: [main]
        jobs:
          swift-format:
            steps:
              - run: AgentGuidelines/Scripts/swift_format.sh lint-strict Package.swift Sources Tests
        """ + "\n",
        to: root.appendingPathComponent(".github/workflows/ci.yml")
    )
    if isPackage {
        try write("// swift-tools-version: 6.0\n", to: root.appendingPathComponent("Package.swift"))
    }
    if let readme {
        try write(readme, to: root.appendingPathComponent("README.md"))
    }
}

func localization(_ value: String, state: String = "translated") -> String {
    #"{"stringUnit":{"state":"\#(state)","value":"\#(value)"}}"#
}

let tests: [(String, () throws -> Void)] = [
    (
        "repository validator accepts the source tree",
        {
            let result = try run([script("Scripts/validate_guidelines.swift")])
            try require(result.succeeded, result.output)
            try require(result.output.contains("Validated"), "validator did not report success")
        }
    ),
    (
        "repository validator rejects configuration drift",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let configuration = fixture.appendingPathComponent("Configurations/Swift/.swift-format")
                var contents = try String(contentsOf: configuration, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "\"NeverForceUnwrap\" : false", with: "\"NeverForceUnwrap\" : true")
                try require(contents.contains("\"NeverForceUnwrap\" : true"), "could not mutate fixture configuration")
                try write(contents, to: configuration)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "configuration drift unexpectedly passed")
                try require(result.output.contains("NeverForceUnwrap must be false"), result.output)
            }
        }
    ),
    (
        "repository validator rejects missing package compiler policy",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: ".treatAllWarnings(as: .error)", with: ".warningsAsErrors()")
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing package warning policy unexpectedly passed")
                try require(result.output.contains("missing package compiler policy"), result.output)
            }
        }
    ),
    (
        "repository validator rejects package upcoming-feature drift",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: ".enableUpcomingFeature(\"NonisolatedNonsendingByDefault\")",
                    with: ".enableUpcomingFeature(\"ExampleFeature\")"
                )
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "package upcoming-feature drift unexpectedly passed")
                try require(
                    result.output.contains(
                        "missing required SwiftPM upcoming feature 'NonisolatedNonsendingByDefault'"),
                    result.output
                )
            }
        }
    ),
    (
        "repository validator rejects missing package plug-in exclusion",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "package plug-in targets for which `Target.plugin(...)` does not expose `swiftSettings`",
                    with: "other package targets"
                )
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing package plug-in exclusion unexpectedly passed")
                try require(
                    result.output.contains("missing package compiler policy unsupported plug-in target exclusion"),
                    result.output)
            }
        }
    ),
    (
        "repository validator rejects missing experimental StrictConcurrency rule",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: ".enableExperimentalFeature(\"StrictConcurrency\")",
                    with: ".enableExperimentalFeature(\"ExampleFeature\")"
                )
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing experimental StrictConcurrency rule unexpectedly passed")
                try require(
                    result.output.contains(
                        "missing package compiler policy experimental StrictConcurrency redundancy rule"), result.output
                )
            }
        }
    ),
    (
        "repository validator rejects missing upcoming StrictConcurrency rule",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: ".enableUpcomingFeature(\"StrictConcurrency\")",
                    with: ".enableUpcomingFeature(\"ExampleFeature\")"
                )
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing upcoming StrictConcurrency rule unexpectedly passed")
                try require(
                    result.output.contains(
                        "missing package compiler policy upcoming StrictConcurrency redundancy rule"), result.output
                )
            }
        }
    ),
    (
        "repository validator rejects missing explicit StrictConcurrency rule",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Packages.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "StrictConcurrency=complete",
                    with: "StrictConcurrency=minimal"
                )
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing explicit StrictConcurrency rule unexpectedly passed")
                try require(
                    result.output.contains(
                        "missing package compiler policy explicit StrictConcurrency redundancy rule"), result.output
                )
            }
        }
    ),
    (
        "repository validator rejects missing Xcode package-parity maintenance",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/Xcode/ProjectSettings.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "../Packages.md#compiler-settings-baseline", with: "package-policy")
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing Xcode package-parity maintenance unexpectedly passed")
                try require(result.output.contains("missing Swift package baseline cross-reference"), result.output)
            }
        }
    ),
    (
        "repository validator rejects missing package audit section",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let skill = fixture.appendingPathComponent(".agents/skills/agent-guidelines-audit/SKILL.md")
                var contents = try String(contentsOf: skill, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "## Audit Swift package settings", with: "## Inspect Swift manifests")
                try write(contents, to: skill)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing package audit section unexpectedly passed")
                try require(result.output.contains("missing Swift package-settings audit"), result.output)
            }
        }
    ),
    (
        "repository validator rejects package audit behavior drift",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let skill = fixture.appendingPathComponent(".agents/skills/agent-guidelines-audit/SKILL.md")
                var contents = try String(contentsOf: skill, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "swift package --package-path <package-root> dump-package",
                    with: "inspect the manifest"
                )
                try write(contents, to: skill)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "package audit behavior drift unexpectedly passed")
                try require(result.output.contains("missing evaluated manifest inspection"), result.output)
            }
        }
    ),
    (
        "repository validator rejects missing observability adoption guidance",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let readme = fixture.appendingPathComponent("README.md")
                var contents = try String(contentsOf: readme, encoding: .utf8)
                contents = contents.replacingOccurrences(of: "runtime-observability contract", with: "runtime contract")
                try write(contents, to: readme)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "missing observability adoption guidance unexpectedly passed")
                try require(
                    result.output.contains("missing runtime observability contract synchronization"), result.output)
            }
        }
    ),
    (
        "repository validator rejects private dependency authentication drift",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let guideline = fixture.appendingPathComponent("Guidelines/CICD.md")
                var contents = try String(contentsOf: guideline, encoding: .utf8)
                contents = contents.replacingOccurrences(
                    of: "isolated disposable or ephemeral self-hosted runner",
                    with: "self-hosted runner")
                try write(contents, to: guideline)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "private dependency authentication drift unexpectedly passed")
                try require(
                    result.output.contains("missing untrusted-code runner isolation"),
                    result.output
                )
            }
        }
    ),
    (
        "repository validator rejects gitignore template drift",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let template = fixture.appendingPathComponent("Templates/.gitignore")
                var contents = try String(contentsOf: template, encoding: .utf8)
                contents = contents.replacingOccurrences(of: "node_modules/\n", with: "")
                try write(contents, to: template)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "gitignore template drift unexpectedly passed")
                try require(
                    result.output.contains("Templates/.gitignore: missing required pattern 'node_modules/'"),
                    result.output
                )
            }
        }
    ),
    (
        "repository validator rejects forbidden tooling in gitignore template",
        {
            try withTemporaryDirectory { temporary in
                let fixture = temporary.appendingPathComponent("repository")
                try copyRepositoryFixture(to: fixture)
                let template = fixture.appendingPathComponent("Templates/.gitignore")
                var contents = try String(contentsOf: template, encoding: .utf8)
                contents += "fastlane/test_output/\n"
                try write(contents, to: template)
                let result = try run([fixture.appendingPathComponent("Scripts/validate_guidelines.swift").path])
                try require(!result.succeeded, "forbidden tooling pattern unexpectedly passed")
                try require(
                    result.output.contains("must not include forbidden tooling pattern 'fastlane/'"),
                    result.output
                )
            }
        }
    ),
    (
        "Markdown checker reports governed wrapping",
        {
            try withTemporaryDirectory { root in
                let markdown = root.appendingPathComponent("Example.md")
                try write(
                    """
                    # Example

                    This paragraph was split
                    across physical lines.

                    - This list item was split
                      across physical lines too.

                    > This quotation was split
                    > across physical lines as well.
                    """ + "\n",
                    to: markdown
                )
                let result = try run([
                    script(".agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift"),
                    markdown.path,
                ])
                try require(!result.succeeded, "wrapped prose unexpectedly passed")
                for expected in [
                    ":3: paragraph spans physical lines 3-4",
                    ":6: list item spans physical lines 6-7",
                    ":9: block quote (depth 1) spans physical lines 9-10",
                ] {
                    try require(result.output.contains(expected), "missing diagnostic: \(expected)\n\(result.output)")
                }
            }
        }
    ),
    (
        "Markdown checker accepts GitHub alerts",
        {
            try withTemporaryDirectory { root in
                let markdown = root.appendingPathComponent("Alerts.md")
                try write(
                    """
                    # Alerts

                    > [!NOTE]
                    > Note body.

                    > [!TIP]
                    > Tip body.

                    > [!IMPORTANT]
                    > Important body.

                    > [!WARNING]
                    > Warning body.

                    > [!CAUTION]
                    > Caution body.
                    """ + "\n",
                    to: markdown
                )
                let result = try run([
                    script(".agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift"),
                    markdown.path,
                ])
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "Markdown checker rejects wrapped or malformed GitHub alerts",
        {
            try withTemporaryDirectory { root in
                let markdown = root.appendingPathComponent("Alerts.md")
                try write(
                    """
                    # Alerts

                    > [!NOTE]
                    > This alert body was split
                    > across physical lines.

                    > [!UNKNOWN]
                    > Unknown alert body.

                    > > [!TIP]
                    > > Nested alert body.

                    > Ordinary quote begins.
                    > [!NOTE]
                    > Ordinary quote continues.
                    """ + "\n",
                    to: markdown
                )
                let result = try run([
                    script(".agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift"),
                    markdown.path,
                ])
                try require(!result.succeeded, "invalid alerts unexpectedly passed")
                for expected in [
                    ":4: block quote (depth 1) spans physical lines 4-5",
                    ":7: block quote (depth 1) spans physical lines 7-8",
                    ":10: block quote (depth 2) spans physical lines 10-11",
                    ":13: block quote (depth 1) spans physical lines 13-15",
                ] {
                    try require(result.output.contains(expected), "missing diagnostic: \(expected)\n\(result.output)")
                }
            }
        }
    ),
    (
        "Markdown checker accepts verbatim structures",
        {
            try withTemporaryDirectory { root in
                let markdown = root.appendingPathComponent("Example.md")
                try write(
                    """
                    ---
                    title: Example
                    ---

                    # Example

                    One physical line of prose.

                    | Role | Folder |
                    |---|---|
                    | App | `App/` |

                    ```text
                    diagram
                    ```

                    <p align="center">
                      <a href="https://example.com">Badge</a>
                    </p>

                    - Parent item.
                      - Nested item.
                    """ + "\n",
                    to: markdown
                )
                let result = try run([
                    script(".agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift"),
                    markdown.path,
                ])
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "String Catalog inspection fails closed for every Git change kind",
        {
            try withTemporaryDirectory { root in
                try initializeRepository(at: root)
                for name in ["Modified.xcstrings", "DeletedThenRenamed.xcstrings", "Copied.xcstrings"] {
                    try write("{}\n", to: root.appendingPathComponent(name))
                }
                try git("add", ".", in: root)
                try git("commit", "-m", "Fixture", in: root)
                try write(#"{"sourceLanguage":"en"}"# + "\n", to: root.appendingPathComponent("Modified.xcstrings"))
                try git("mv", "DeletedThenRenamed.xcstrings", "Renamed.xcstrings", in: root)
                try fileManager.copyItem(
                    at: root.appendingPathComponent("Copied.xcstrings"),
                    to: root.appendingPathComponent("Added.xcstrings")
                )
                try git("add", "Added.xcstrings", in: root)
                try write("{}\n", to: root.appendingPathComponent("Untracked.xcstrings"))
                let result = try run(
                    [
                        script(".agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift"),
                        "--repository", root.path, "--base-ref", "HEAD",
                    ]
                )
                try require(!result.succeeded, "missing editor evidence unexpectedly passed")
                for name in ["Added.xcstrings", "Modified.xcstrings", "Renamed.xcstrings", "Untracked.xcstrings"] {
                    try require(
                        result.output.contains("missing Xcode catalog-editor inspection evidence: \(name)"),
                        "missing changed catalog \(name): \(result.output)")
                }
                try require(result.output.contains("--evidence-output is required"), result.output)
            }
        }
    ),
    (
        "String Catalog inspection records structured zero-diagnostic evidence",
        {
            try withTemporaryDirectory { temporary in
                let root = temporary.appendingPathComponent("repository")
                try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
                try initializeRepository(at: root)
                let catalog = root.appendingPathComponent("Localizable.xcstrings")
                try write("{}\n", to: catalog)
                try git("add", ".", in: root)
                try git("commit", "-m", "Fixture", in: root)
                try write(#"{"sourceLanguage":"en"}"# + "\n", to: catalog)
                let evidence = temporary.appendingPathComponent("evidence.json")
                let result = try run(
                    [
                        script(".agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift"),
                        "--repository", root.path, "--base-ref", "HEAD", "--inspected-catalog",
                        "Localizable.xcstrings", "--evidence-output", evidence.path,
                    ]
                )
                try require(result.succeeded, result.output)
                let data = try Data(contentsOf: evidence)
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let catalogs = object?["catalogs"] as? [[String: Any]]
                try require(object?["baseRef"] as? String == "HEAD", "base ref was not recorded")
                try require(
                    (object?["xcodeVersion"] as? String)?.contains("Xcode") == true, "Xcode version was not recorded")
                try require(
                    catalogs?.first?["path"] as? String == "Localizable.xcstrings", "catalog path was not recorded")
                try require(catalogs?.first?["catalogEditorWarnings"] as? Int == 0, "warning count was not zero")
                try require(catalogs?.first?["catalogEditorErrors"] as? Int == 0, "error count was not zero")
            }
        }
    ),
    (
        "symbol preparation preserves translations and stale entries",
        {
            try withTemporaryDirectory { root in
                let catalog = root.appendingPathComponent("Localizable.xcstrings")
                try write(
                    """
                    {"sourceLanguage":"en","strings":{
                      "Legacy value":{"comment":"Visible title","extractionState":"extracted_with_value","localizations":{"de":\(localization("Alter Wert"))}},
                      "Old value":{"extractionState":"stale","localizations":{"en":\(localization("Old"))}}
                    },"version":"1.1"}
                    """ + "\n",
                    to: catalog
                )
                let check = try run([script("Scripts/prepare_localizable_symbols.swift"), catalog.path, "--check"])
                try require(!check.succeeded, "unprepared catalog unexpectedly passed")
                let preparation = try run([script("Scripts/prepare_localizable_symbols.swift"), catalog.path])
                try require(preparation.succeeded, preparation.output)
                let data = try Data(contentsOf: catalog)
                let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let strings = object?["strings"] as? [String: Any]
                let active = strings?["Legacy value"] as? [String: Any]
                let activeLocalizations = active?["localizations"] as? [String: Any]
                let stale = strings?["Old value"] as? [String: Any]
                try require(active?["extractionState"] as? String == "manual", "active key was not made manual")
                try require(active?["comment"] as? String == "Visible title", "comment was not preserved")
                try require(
                    activeLocalizations?["de"] != nil && activeLocalizations?["en"] != nil,
                    "translations were not preserved")
                try require(stale?["extractionState"] as? String == "stale", "stale key was revived")
                let finalCheck = try run([script("Scripts/prepare_localizable_symbols.swift"), catalog.path, "--check"])
                try require(finalCheck.succeeded, finalCheck.output)
            }
        }
    ),
    (
        "symbol preparation rejects manual entries without source copy",
        {
            try withTemporaryDirectory { root in
                let catalog = root.appendingPathComponent("Localizable.xcstrings")
                try write(
                    #"{"sourceLanguage":"en","strings":{"semanticKey":{"extractionState":"manual","localizations":{"de":{"stringUnit":{"state":"translated","value":"Wert"}}}}}}"#,
                    to: catalog
                )
                let result = try run([script("Scripts/prepare_localizable_symbols.swift"), catalog.path])
                try require(!result.succeeded, "invalid manual key unexpectedly passed")
                try require(result.output.contains("manual entry has no en source value"), result.output)
            }
        }
    ),
    (
        "String Catalog validator accepts valid symbols, states, and formats",
        {
            try withTemporaryDirectory { root in
                let catalogs = root.appendingPathComponent("Catalogs")
                let sources = root.appendingPathComponent("Sources")
                try fileManager.createDirectory(at: sources, withIntermediateDirectories: true)
                try write(
                    """
                    {"sourceLanguage":"en","strings":{"summary":{"extractionState":"manual","localizations":{
                      "en":\(localization("%1$(count)lld items")),
                      "de":\(localization("%1$(count)lld Einträge", state: "machine_translated"))
                    }}}}
                    """ + "\n",
                    to: catalogs.appendingPathComponent("Localizable.xcstrings")
                )
                let result = try run(
                    [
                        script("Scripts/validate_string_catalogs.swift"), "--catalog-directory", catalogs.path,
                        "--source-directory", sources.path, "--required-language", "de",
                    ]
                )
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "String Catalog validator reports independent catalog defects",
        {
            try withTemporaryDirectory { root in
                let catalogs = root.appendingPathComponent("Catalogs")
                let sources = root.appendingPathComponent("Sources")
                try fileManager.createDirectory(at: sources, withIntermediateDirectories: true)
                try write(
                    """
                    {"sourceLanguage":"en","strings":{
                      "count":{"extractionState":"manual","localizations":{"en":\(localization("%1$(count)lld items")),"de":\(localization("%1$(value)@ Einträge", state: "needs_review"))}},
                      "Old":{"extractionState":"stale"}
                    }}
                    """ + "\n",
                    to: catalogs.appendingPathComponent("Localizable.xcstrings")
                )
                let result = try run(
                    [
                        script("Scripts/validate_string_catalogs.swift"), "--catalog-directory", catalogs.path,
                        "--source-directory", sources.path, "--required-language", "de", "--required-language", "fr",
                    ]
                )
                try require(!result.succeeded, "invalid catalog unexpectedly passed")
                for expected in [
                    "stale extracted strings", "format specifiers", "required localization is missing",
                    "unfinished states needs_review",
                ] {
                    try require(result.output.contains(expected), "missing diagnostic \(expected): \(result.output)")
                }
            }
        }
    ),
    (
        "consumer validator rejects package README License headings",
        {
            for readme in [
                "# Package\n\n## License\n", "# Package\n\n#### lIcEnSe ####\n",
                "# Package\n\nLicense\n-------\n", "# Package\n\nLICENSE\n=======\n",
            ] {
                try withTemporaryDirectory { root in
                    try createConsumerFixture(at: root, isPackage: true, readme: readme)
                    let result = try run([
                        script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path,
                    ])
                    try require(!result.succeeded, "package License heading unexpectedly passed")
                    try require(result.output.contains("must not contain a dedicated License heading"), result.output)
                }
            }
        }
    ),
    (
        "consumer validator rejects standalone package README license prose",
        {
            try withTemporaryDirectory { root in
                try createConsumerFixture(
                    at: root,
                    isPackage: true,
                    readme: "# Example\n\nExample is available under the MIT license. See [LICENSE](LICENSE).\n"
                )
                let result = try run([
                    script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path,
                ])
                try require(!result.succeeded, "standalone package license prose unexpectedly passed")
                try require(
                    result.output.contains("must not contain a standalone license-description paragraph"),
                    result.output
                )
            }
        }
    ),
    (
        "consumer validator accepts package license badge and absent README",
        {
            try withTemporaryDirectory { root in
                try createConsumerFixture(
                    at: root,
                    isPackage: true,
                    readme: """
                        # Example

                        ![License](https://img.shields.io/badge/License-MIT-green.svg)

                        See [LICENSE](LICENSE) when verifying redistribution terms.

                        ````markdown
                        ```markdown
                        ## License section example

                        Example is available under the MIT license. See [LICENSE](LICENSE).
                        ```
                        ````

                        ~~~text
                        # License
                        ~~~
                        """ + "\n"
                )
                let result = try run([
                    script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path,
                ])
                try require(result.succeeded, result.output)
            }
            try withTemporaryDirectory { root in
                try createConsumerFixture(at: root, isPackage: true)
                let result = try run([
                    script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path,
                ])
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "consumer validator limits README license policy to package roots",
        {
            try withTemporaryDirectory { root in
                try createConsumerFixture(at: root, isPackage: false, readme: "# App\n\n## License\n")
                try write(
                    "# License\n\nStandalone documentation may discuss licensing.\n",
                    to: root.appendingPathComponent("Documentation/README.md")
                )
                let result = try run([
                    script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path,
                ])
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "consumer validator accepts synchronized integration",
        {
            try withTemporaryDirectory { root in
                try fileManager.createSymbolicLink(
                    at: root.appendingPathComponent("AgentGuidelines"), withDestinationURL: repositoryRoot)
                try fileManager.copyItem(
                    at: repositoryRoot.appendingPathComponent("Templates/AGENTS.md"),
                    to: root.appendingPathComponent("AGENTS.md"))
                try write("AgentGuidelines/** linguist-generated\n", to: root.appendingPathComponent(".gitattributes"))
                let skillParent = root.appendingPathComponent(".agents/skills")
                try fileManager.createDirectory(at: skillParent, withIntermediateDirectories: true)
                try fileManager.createSymbolicLink(
                    at: skillParent.appendingPathComponent("agent-guidelines-audit"),
                    withDestinationURL: repositoryRoot.appendingPathComponent(".agents/skills/agent-guidelines-audit")
                )
                try fileManager.createSymbolicLink(
                    at: root.appendingPathComponent(".swift-format"),
                    withDestinationURL: repositoryRoot.appendingPathComponent("Configurations/Swift/.swift-format")
                )
                try fileManager.createSymbolicLink(
                    at: root.appendingPathComponent(".editorconfig"),
                    withDestinationURL: repositoryRoot.appendingPathComponent("Configurations/Swift/.editorconfig")
                )
                try write(
                    """
                    name: CI
                    on:
                      pull_request:
                      push:
                        branches: [main]
                    jobs:
                      swift-format:
                        steps:
                          - run: AgentGuidelines/Scripts/swift_format.sh lint-strict Sources
                    """ + "\n",
                    to: root.appendingPathComponent(".github/workflows/ci.yml")
                )
                let result = try run([script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path])
                try require(result.succeeded, result.output)
            }
        }
    ),
    (
        "consumer validator rejects copied audit skill and contract drift",
        {
            try withTemporaryDirectory { root in
                try fileManager.createSymbolicLink(
                    at: root.appendingPathComponent("AgentGuidelines"), withDestinationURL: repositoryRoot)
                let template = try String(
                    contentsOf: repositoryRoot.appendingPathComponent("Templates/AGENTS.md"), encoding: .utf8)
                try write(
                    template.replacingOccurrences(
                        of: "P0/P1", with: "P0", options: [], range: template.range(of: "P0/P1")),
                    to: root.appendingPathComponent("AGENTS.md"))
                try write("*.md text\n", to: root.appendingPathComponent(".gitattributes"))
                let skill = root.appendingPathComponent(".agents/skills/agent-guidelines-audit")
                try fileManager.createDirectory(at: skill, withIntermediateDirectories: true)
                try write("stale copy\n", to: skill.appendingPathComponent("SKILL.md"))
                let result = try run([script("Scripts/validate_consumer_setup.swift"), "--consumer-root", root.path])
                try require(!result.succeeded, "invalid consumer unexpectedly passed")
                for expected in ["code-review contract does not match", "linguist-generated", "must be a symlink"] {
                    try require(result.output.contains(expected), "missing diagnostic \(expected): \(result.output)")
                }
            }
        }
    ),
]

var failures = 0
for (name, test) in tests {
    do {
        try test()
        print("PASS \(name)")
    } catch {
        failures += 1
        FileHandle.standardError.write(Data("FAIL \(name): \(error)\n".utf8))
    }
}

if failures > 0 {
    FileHandle.standardError.write(Data("\(failures) of \(tests.count) tests failed.\n".utf8))
    exit(1)
}

print("All \(tests.count) native Swift tests passed.")
