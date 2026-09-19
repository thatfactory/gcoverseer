#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let readme = root.appendingPathComponent("README.md")
let versionFile = root.appendingPathComponent("VERSION")
let changelog = root.appendingPathComponent("CHANGELOG.md")
let swiftFormatConfiguration = root.appendingPathComponent("Configurations/Swift/.swift-format")
let editorConfiguration = root.appendingPathComponent("Configurations/Swift/.editorconfig")
let swiftFormatScript = root.appendingPathComponent("Scripts/swift_format.sh")
let swiftFormatGuideline = root.appendingPathComponent("Guidelines/Swift/SwiftFormat.md")
let localizationGuideline = root.appendingPathComponent("Guidelines/Localization.md")
let appStoreGuideline = root.appendingPathComponent("Guidelines/AppStore.md")
let xcodeProjectSettingsGuideline = root.appendingPathComponent("Guidelines/Xcode/ProjectSettings.md")
let localizationPreparationScript = root.appendingPathComponent("Scripts/prepare_localizable_symbols.swift")
let localizationValidationScript = root.appendingPathComponent("Scripts/validate_string_catalogs.swift")
let consumerSetupScript = root.appendingPathComponent("Scripts/validate_consumer_setup.swift")
let testRunner = root.appendingPathComponent("Tests/run_tests.swift")
let auditSkill = root.appendingPathComponent(".agents/skills/agent-guidelines-audit/SKILL.md")
let markdownWrappingScript = root.appendingPathComponent(
    ".agents/skills/agent-guidelines-audit/scripts/check_markdown_wrapping.swift"
)
let stringCatalogInspectionScript = root.appendingPathComponent(
    ".agents/skills/agent-guidelines-audit/scripts/check_xcstrings_inspection.swift"
)
let developmentGuideline = root.appendingPathComponent("Guidelines/Development.md")
let cicdGuideline = root.appendingPathComponent("Guidelines/CICD.md")
let documentationGuideline = root.appendingPathComponent("Guidelines/Documentation.md")
let packagesGuideline = root.appendingPathComponent("Guidelines/Packages.md")
let agentsTemplate = root.appendingPathComponent("Templates/AGENTS.md")
let gitignoreTemplate = root.appendingPathComponent("Templates/.gitignore")
let gitignoreGuideline = root.appendingPathComponent("Guidelines/Git/IgnoreFiles.md")

let expectedSwiftFormatRules: [String: Bool] = [
    "AllPublicDeclarationsHaveDocumentation": false,
    "AlwaysUseLiteralForEmptyCollectionInit": true,
    "AlwaysUseLowerCamelCase": true,
    "AmbiguousTrailingClosureOverload": true,
    "AvoidRetroactiveConformances": true,
    "BeginDocumentationCommentWithOneLineSummary": false,
    "DoNotUseSemicolons": true,
    "DontRepeatTypeInStaticProperties": true,
    "FileScopedDeclarationPrivacy": true,
    "FullyIndirectEnum": true,
    "GroupNumericLiterals": true,
    "IdentifiersMustBeASCII": true,
    "NeverForceUnwrap": false,
    "NeverUseForceTry": true,
    "NeverUseImplicitlyUnwrappedOptionals": false,
    "NoAccessLevelOnExtensionDeclaration": true,
    "NoAssignmentInExpressions": true,
    "NoBlockComments": true,
    "NoCasesWithOnlyFallthrough": true,
    "NoEmptyLinesOpeningClosingBraces": true,
    "NoEmptyTrailingClosureParentheses": true,
    "NoLabelsInCasePatterns": true,
    "NoLeadingUnderscores": false,
    "NoParensAroundConditions": true,
    "NoPlaygroundLiterals": true,
    "NoVoidReturnOnFunctionSignature": true,
    "OmitExplicitReturns": false,
    "OneCasePerLine": true,
    "OneVariableDeclarationPerLine": true,
    "OnlyOneTrailingClosureArgument": true,
    "OrderedImports": true,
    "ReplaceForEachWithForLoop": true,
    "ReturnVoidInsteadOfEmptyTuple": true,
    "TypeNamesShouldBeCapitalized": true,
    "UseEarlyExits": false,
    "UseExplicitNilCheckInConditions": true,
    "UseLetInEveryBoundCaseVariable": true,
    "UseShorthandTypeNames": true,
    "UseSingleLinePropertyGetter": true,
    "UseSynthesizedInitializer": true,
    "UseTripleSlashForDocumentationComments": true,
    "UseWhereClausesInForLoops": true,
    "ValidateDocumentationComments": true,
]

let markdownLinkPattern = #"\[[^\]]+\]\(([^)]+)\)"#
let semanticVersionPattern =
    #"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-((?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*))*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$"#
let forbiddenContent = [
    "/" + "Users" + "/": "personal absolute path",
    "file" + "://": "local file URL",
    "mobile-ios-" + "chauffeur": "work-repository identifier",
    "black" + "lane": "work-repository identifier",
]
let upcomingFeatureSettings = [
    "SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE",
    "SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN",
    "SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION",
    "SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION",
    "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY",
    "SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES",
    "SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY",
    "SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY",
    "SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS",
    "SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS",
    "SWIFT_UPCOMING_FEATURE_INFER_ISOLATED_CONFORMANCES",
    "SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES",
    "SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT",
    "SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY",
    "SWIFT_UPCOMING_FEATURE_NONFROZEN_ENUM_EXHAUSTIVITY",
    "SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT",
    "SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION",
]
let packageUpcomingFeatures = [
    "ExistentialAny",
    "InferIsolatedConformances",
    "InternalImportsByDefault",
    "MemberImportVisibility",
    "NonisolatedNonsendingByDefault",
]

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

/// Returns a repository-relative path.
func relativePath(_ url: URL) -> String {
    url.standardizedFileURL.path.replacingOccurrences(of: root.standardizedFileURL.path + "/", with: "")
}

/// Reads UTF-8 text or records an error.
func readText(_ url: URL, errors: inout [String]) -> String? {
    do {
        return try String(contentsOf: url, encoding: .utf8)
    } catch {
        errors.append("\(relativePath(url)): cannot read file: \(error.localizedDescription)")
        return nil
    }
}

/// Recursively discovers regular files while excluding repository internals and build caches.
func recursiveFiles(below directory: URL) -> [URL] {
    guard
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        )
    else {
        return []
    }
    var files: [URL] = []
    for case let url as URL in enumerator {
        let relative = relativePath(url)
        if relative.split(separator: "/").contains(where: { $0 == ".git" || $0 == ".build" || $0 == "__pycache__" }) {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                enumerator.skipDescendants()
            }
            continue
        }
        if (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
            files.append(url)
        }
    }
    return files.sorted { $0.path < $1.path }
}

/// Returns all public-text files governed by the privacy scan.
func textFiles() -> [URL] {
    let suffixes: Set<String> = ["md", "sh", "swift", "txt", "yml", "yaml"]
    var files = recursiveFiles(below: root).filter { suffixes.contains($0.pathExtension.lowercased()) }
    for url in [versionFile, root.appendingPathComponent("LICENSE"), swiftFormatConfiguration, editorConfiguration]
    where FileManager.default.fileExists(atPath: url.path) {
        files.append(url)
    }
    return Array(Set(files)).sorted { $0.path < $1.path }
}

/// Resolves a relative Markdown link target within the source repository.
func resolveLink(source: URL, rawTarget: String) -> URL? {
    var target = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
    target = target.components(separatedBy: "#").first ?? target
    if target.isEmpty || ["#", "http://", "https://", "mailto:"].contains(where: target.hasPrefix) {
        return nil
    }
    let parts = NSString(string: target).pathComponents
    if let index = parts.firstIndex(of: "AgentGuidelines") {
        let suffix = parts.dropFirst(index + 1).joined(separator: "/")
        return root.appendingPathComponent(suffix).standardizedFileURL
    }
    return source.deletingLastPathComponent().appendingPathComponent(target).standardizedFileURL
}

/// Validates all relative Markdown link targets.
func validateLinks(_ errors: inout [String]) {
    for source in recursiveFiles(below: root).filter({ $0.pathExtension.lowercased() == "md" }) {
        guard let contents = readText(source, errors: &errors) else {
            continue
        }
        for match in matches(markdownLinkPattern, in: contents) {
            guard let rawTarget = capture(1, from: match, in: contents),
                let resolved = resolveLink(source: source, rawTarget: rawTarget)
            else {
                continue
            }
            if !FileManager.default.fileExists(atPath: resolved.path) {
                errors.append("\(relativePath(source)): missing link target '\(rawTarget)'")
            }
        }
    }
}

/// Validates that the README catalogs every shared guide.
func validateCatalog(_ errors: inout [String]) {
    guard let contents = readText(readme, errors: &errors) else {
        return
    }
    let guideRoot = root.appendingPathComponent("Guidelines")
    for guide in recursiveFiles(below: guideRoot).filter({ $0.pathExtension.lowercased() == "md" }) {
        let relative = relativePath(guide)
        if !contents.contains("](\(relative))") {
            errors.append("README.md: guideline is not cataloged: \(relative)")
        }
    }
}

/// Validates the semantic version and matching changelog heading.
func validateVersion(_ errors: inout [String]) {
    guard let version = readText(versionFile, errors: &errors)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
        return
    }
    if matches(semanticVersionPattern, in: version).isEmpty {
        errors.append("VERSION: invalid semantic version '\(version)'")
    }
    if let contents = readText(changelog, errors: &errors), !contents.contains("## [\(version)]") {
        errors.append("CHANGELOG.md: missing release heading for \(version)")
    }
}

/// Validates required README installation and integration contracts.
func validateReadmeContract(_ errors: inout [String]) {
    guard let contents = readText(readme, errors: &errors) else {
        return
    }
    if let version = readText(versionFile, errors: &errors)?.trimmingCharacters(in: .whitespacesAndNewlines),
        contents.components(separatedBy: version).count - 1 != 2
    {
        errors.append("README.md: installation and consumer-update commands must both use VERSION \(version)")
    }
    let required = [
        "alt=\"Xcode MCP\"": "Xcode MCP badge alt text",
        "thatfactory/agent-guidelines/actions/workflows/ci.yml": "CI badge repository",
        "--prefix=AgentGuidelines": "subtree destination",
        "https://github.com/thatfactory/agent-guidelines.git": "subtree remote",
        "git subtree add": "subtree installation command",
        "git subtree pull": "subtree update command",
        "AgentGuidelines/** linguist-generated": "generated subtree attribute",
        "AgentGuidelines/Configurations/Swift/.swift-format": "swift-format symlink command",
        "AgentGuidelines/Configurations/Swift/.editorconfig": "EditorConfig symlink command",
        ".agents/skills/agent-guidelines-audit": "completion-audit skill setup",
        "validate_consumer_setup.swift": "consumer setup validation command",
        "--require-swift-format": "explicit Swift-format adoption validation",
        "documentation-maintenance contract": "documentation contract synchronization",
        "external-dependency contract": "external dependency contract synchronization",
        "runtime-observability contract": "runtime observability contract synchronization",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("README.md: missing \(description): '\(value)'")
    }
}

/// Validates that public files contain no private or consumer-specific content.
func validatePublicContent(_ errors: inout [String]) {
    for url in textFiles() {
        guard let contents = readText(url, errors: &errors) else {
            continue
        }
        for (forbidden, description) in forbiddenContent
        where contents.localizedCaseInsensitiveContains(forbidden) {
            errors.append("\(relativePath(url)): contains \(description): '\(forbidden)'")
        }
    }
}

/// Returns whether two Foundation JSON values are equal.
func jsonEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    guard let lhs, let rhs else {
        return lhs == nil && rhs == nil
    }
    return (lhs as AnyObject).isEqual(rhs)
}

/// Validates the shared swift-format configuration.
func validateSwiftFormatConfiguration(_ errors: inout [String]) {
    let configuration: [String: Any]
    do {
        let data = try Data(contentsOf: swiftFormatConfiguration)
        guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "GuidelineValidation", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "root value is not an object"
                ])
        }
        configuration = parsed
    } catch {
        errors.append("Configurations/Swift/.swift-format: invalid JSON: \(error.localizedDescription)")
        return
    }
    let expectedValues: [String: Any] = [
        "indentation": ["spaces": 4],
        "indentSwitchCaseLabels": false,
        "lineLength": 120,
        "tabWidth": 4,
        "version": 1,
    ]
    for (key, expected) in expectedValues where !jsonEqual(configuration[key], expected) {
        errors.append(
            "Configurations/Swift/.swift-format: \(key) must be \(expected), found \(String(describing: configuration[key]))"
        )
    }
    let orderedImports = configuration["orderedImports"] as? [String: Any]
    if orderedImports?["includeConditionalImports"] as? Bool != true {
        errors.append(
            "Configurations/Swift/.swift-format: orderedImports.includeConditionalImports must be true, found "
                + String(describing: orderedImports?["includeConditionalImports"])
        )
    }
    guard let rules = configuration["rules"] as? [String: Any], !rules.isEmpty else {
        errors.append("Configurations/Swift/.swift-format: rules must be an exhaustive non-empty object")
        return
    }
    let expectedKeys = Set(expectedSwiftFormatRules.keys)
    let actualKeys = Set(rules.keys)
    let missing = expectedKeys.subtracting(actualKeys).sorted()
    let unexpected = actualKeys.subtracting(expectedKeys).sorted()
    if !missing.isEmpty || !unexpected.isEmpty {
        errors.append(
            "Configurations/Swift/.swift-format: rule map mismatch; missing=\(missing), unexpected=\(unexpected)")
    }
    for rule in expectedKeys.intersection(actualKeys).sorted() {
        let expected = expectedSwiftFormatRules[rule] ?? false
        if rules[rule] as? Bool != expected {
            errors.append(
                "Configurations/Swift/.swift-format: \(rule) must be "
                    + "\(expected), found \(String(describing: rules[rule]))"
            )
        }
    }
}

/// Validates the shared EditorConfig values.
func validateEditorConfiguration(_ errors: inout [String]) {
    guard let contents = readText(editorConfiguration, errors: &errors) else {
        return
    }
    let required = [
        "root = true", "[*.swift]", "indent_style = space", "indent_size = 4", "tab_width = 4",
        "max_line_length = 120", "end_of_line = lf", "insert_final_newline = true",
        "trim_trailing_whitespace = true",
    ]
    for value in required.sorted() where !contents.contains(value) {
        errors.append("Configurations/Swift/.editorconfig: missing '\(value)'")
    }
}

/// Validates that an expected executable file exists.
func validateExecutable(_ url: URL, description: String, errors: inout [String]) {
    guard FileManager.default.fileExists(atPath: url.path) else {
        errors.append("\(relativePath(url)): missing \(description)")
        return
    }
    if !FileManager.default.isExecutableFile(atPath: url.path) {
        errors.append("\(relativePath(url)): \(description) is not executable")
    }
}

/// Validates native Swift ownership for repository automation.
func validateScriptLanguages(_ errors: inout [String]) {
    let scriptsRoot = root.appendingPathComponent("Scripts")
    let allowedShellPath = "Scripts/swift_format.sh"
    for url in recursiveFiles(below: scriptsRoot) {
        let relative = relativePath(url)
        if url.pathExtension == "swift" || relative == allowedShellPath {
            continue
        }
        errors.append("\(relative): repository scripts must use Swift; only \(allowedShellPath) is retained")
    }
    let auditScriptsRoot = root.appendingPathComponent(".agents/skills/agent-guidelines-audit/scripts")
    for url in recursiveFiles(below: auditScriptsRoot) where url.pathExtension != "swift" {
        errors.append("\(relativePath(url)): audit helper scripts must use Swift")
    }
    let testsRoot = root.appendingPathComponent("Tests")
    for url in recursiveFiles(below: testsRoot) where url.pathExtension != "swift" {
        errors.append("\(relativePath(url)): repository test automation must use Swift")
    }
    validateExecutable(testRunner, description: "native Swift test runner", errors: &errors)
    for workflowPath in [".github/workflows/ci.yml", ".github/workflows/release.yml"] {
        let workflow = root.appendingPathComponent(workflowPath)
        guard let contents = readText(workflow, errors: &errors) else { continue }
        for required in ["Tests/run_tests.swift", "Scripts/validate_guidelines.swift"]
        where !contents.contains(required) {
            errors.append("\(workflowPath): missing native validation command '\(required)'")
        }
        if contents.localizedCaseInsensitiveContains("python") {
            errors.append("\(workflowPath): repository validation must not require Python")
        }
    }
}

/// Validates the shared Swift-format workflow guide.
func validateSwiftFormatGuideline(_ errors: inout [String]) {
    guard let contents = readText(swiftFormatGuideline, errors: &errors) else {
        return
    }
    let required = [
        "## Swift package integration": "Swift package workflow",
        "format-and-lint \\": "local package formatting command",
        "Package.swift": "package manifest formatting scope",
        "## CI integration": "CI workflow",
        "lint-strict \\": "strict CI command",
        "Never run `format` or `format-and-lint` in CI": "non-mutating CI rule",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/Swift/SwiftFormat.md: missing \(description): '\(value)'")
    }
}

/// Validates the documentation-maintenance policy.
func validateDocumentationGuideline(_ errors: inout [String]) {
    guard let contents = readText(documentationGuideline, errors: &errors) else {
        return
    }
    let required = [
        "Documentation is part of implementation": "implementation-time documentation rule",
        "Regardless of change size": "existing-document staleness rule",
        "inaccurate, incomplete, misleading, or obsolete": "stale documentation criteria",
        "A small change that leaves durable knowledge and existing documentation accurate":
            "minor-change documentation churn guardrail",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/Documentation.md: missing \(description): '\(value)'")
    }
}

/// Validates the generated-symbol localization workflow.
func validateLocalizationGuideline(_ errors: inout [String]) {
    guard let contents = readText(localizationGuideline, errors: &errors) else {
        return
    }
    let required = [
        "using-generated-localizable-symbols-in-your-code": "Apple generated-symbol reference",
        "localizing-your-app-using-agents": "Apple agent-localization reference",
        "Xcode-generated `LocalizedStringResource` symbols": "generated-symbol default",
        "prepare_localizable_symbols.swift": "shared symbol-preparation workflow",
        "validate_string_catalogs.swift": "shared catalog-validation workflow",
        "stale extracted entry": "stale-entry policy",
        "marked `new` or `needs_review`": "translation-state policy",
        "placeholder positions, semantic names, and conversion types": "format-signature policy",
        "product voice, terminology": "consumer-specific translation boundary",
        "small repository-owned wrapper": "consumer configuration boundary",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/Localization.md: missing \(description): '\(value)'")
    }
}

/// Validates native reusable localization scripts.
func validateLocalizationScripts(_ errors: inout [String]) {
    let scripts: [(URL, [String])] = [
        (localizationPreparationScript, ["prepareCatalog", "symbolIssues", "--check"]),
        (
            localizationValidationScript,
            [
                "--catalog-directory", "--source-directory", "--required-language", "formatSignatureIssues",
                "translationStateIssues", "literalLocalizationReferences",
            ]
        ),
    ]
    for (script, requiredValues) in scripts {
        validateExecutable(script, description: "localization script", errors: &errors)
        guard let contents = readText(script, errors: &errors) else {
            continue
        }
        if contents.contains("Headroom") {
            errors.append("\(relativePath(script)): contains consumer-specific logic")
        }
        for value in requiredValues where !contents.contains(value) {
            errors.append("\(relativePath(script)): missing localization behavior '\(value)'")
        }
    }
}

/// Validates the Xcode project-settings contract.
func validateXcodeProjectSettingsGuideline(_ errors: inout [String]) {
    guard let contents = readText(xcodeProjectSettingsGuideline, errors: &errors) else {
        return
    }
    let required = [
        "https://developer.apple.com/documentation/xcode/build-settings-reference":
            "official Apple build-settings reference",
        "GCC_TREAT_WARNINGS_AS_ERRORS": "C and Objective-C warning policy",
        "MTL_TREAT_WARNINGS_AS_ERRORS": "Metal warning policy",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS": "Swift warning policy",
        "SWIFT_APPROACHABLE_CONCURRENCY = YES": "approachable concurrency baseline",
        "SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor": "default actor isolation baseline",
        "SWIFT_STRICT_CONCURRENCY = complete": "strict concurrency baseline",
        "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO": "export-compliance build-setting baseline",
        "ITSAppUsesNonExemptEncryption`](https://developer.apple.com/": "official export-compliance key reference",
        "built `Info.plist`": "built export-compliance verification",
        "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = YES": "documented non-exempt encryption exception",
        "newest stable Swift language mode": "future-facing Swift language policy",
        "Enable each feature that remains opt-in": "language-mode-aware upcoming-feature policy",
        "warnings-as-errors can turn that diagnostic into a build failure": "redundant upcoming-feature safety rule",
        "Xcode 27 inventory to evaluate": "Xcode 27 upcoming-feature inventory",
        "project-level `.xcconfig`": "project-level configuration ownership",
        "unit-test and UI-test targets": "test-target effective-value audit",
        "nearest applicable `AGENTS.md`": "local exception source",
        "condition for removing or revisiting the exception": "exception lifecycle",
        "## Swift package parity": "Swift package parity section",
        "../Packages.md#compiler-settings-baseline": "Swift package baseline cross-reference",
        "Whenever this Xcode project baseline adds, removes, or changes a Swift or Clang compiler policy":
            "package applicability maintenance rule",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/Xcode/ProjectSettings.md: missing \(description): '\(value)'")
    }
    for setting in upcomingFeatureSettings where !contents.contains(setting) {
        errors.append(
            "Guidelines/Xcode/ProjectSettings.md: missing Xcode 27 upcoming-feature inventory entry: '\(setting)'")
    }
}

/// Validates the Swift package compiler-settings contract.
func validatePackageCompilerSettingsGuideline(_ errors: inout [String]) {
    guard let contents = readText(packagesGuideline, errors: &errors) else {
        return
    }
    let required = [
        "## Compiler settings baseline": "compiler-settings baseline section",
        "Xcode/ProjectSettings.md": "Xcode baseline cross-reference",
        "swiftLanguageModes": "package-level Swift language mode",
        ".treatAllWarnings(as: .error)": "typed warnings-as-errors policy",
        "Swift 6 language mode enables complete concurrency checking unconditionally":
            "Swift 6 strict-concurrency explanation",
        ".enableUpcomingFeature(\"StrictConcurrency\")":
            "upcoming StrictConcurrency redundancy rule",
        ".enableExperimentalFeature(\"StrictConcurrency\")":
            "experimental StrictConcurrency redundancy rule",
        "StrictConcurrency=complete": "explicit StrictConcurrency redundancy rule",
        "`.defaultIsolation(MainActor.self)` is intentionally not part":
            "default MainActor isolation exclusion",
        "package plug-in targets for which `Target.plugin(...)` does not expose `swiftSettings`":
            "unsupported plug-in target exclusion",
        "Retain no redundant upcoming features": "redundant upcoming-feature prohibition",
        "condition for revisiting or removing the exception": "package-setting exception lifecycle",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/Packages.md: missing package compiler policy \(description): '\(value)'")
    }
    for feature in packageUpcomingFeatures where !contents.contains(".enableUpcomingFeature(\"\(feature)\")") {
        errors.append("Guidelines/Packages.md: missing required SwiftPM upcoming feature '\(feature)'")
    }
}

/// Validates the shared App Store metadata workflow.
func validateAppStoreGuideline(_ errors: inout [String]) {
    guard let contents = readText(appStoreGuideline, errors: &errors) else {
        return
    }
    let required = [
        "app-store-connect-mcp": "MCP source",
        "AppStore/": "repository metadata root",
        "validate_repository": "repository validation",
        "plan_metadata_changes": "metadata planning",
        "plan_screenshot_changes": "screenshot planning",
        "apply_plan": "immutable plan application",
        "get_operation_status": "uncertain-outcome recovery",
        "noOp: true": "remote reconciliation",
        ".appstore-connect-mcp/": "ignored operational state",
        "does not authorize submitting": "submission boundary",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append("Guidelines/AppStore.md: missing \(description): '\(value)'")
    }
}

/// Validates the native-first dependency policy.
func validateExternalDependencyPolicy(_ errors: inout [String]) {
    if let contents = readText(developmentGuideline, errors: &errors) {
        let required = [
            "## External dependencies": "external dependency policy section",
            "Do not introduce a new third-party source or binary dependency": "native and first-party default",
            "explicit approval from the repository owner": "repository-owner approval gate",
            "durable repository documentation": "durable exception record",
            "Tooling dependencies explicitly required by these shared guidelines": "tooling-only exception",
            "CocoaPods and Carthage are forbidden": "forbidden package managers",
            "Use Swift Package Manager for package dependencies": "Swift Package Manager requirement",
            "## Post-merge cleanup": "post-merge cleanup section",
            "fast-forward-only pull": "safe primary-branch update",
            "delete the merged local feature branch": "merged local branch removal",
            "Confirm the remote feature branch is absent": "remote branch cleanup verification",
        ]
        for (value, description) in required where !contents.contains(value) {
            errors.append("Guidelines/Development.md: missing \(description): '\(value)'")
        }
    }
    if let contents = readText(cicdGuideline, errors: &errors) {
        let required = [
            "## Tooling and automation": "CI/CD tooling policy section",
            "## Private repository dependencies": "private repository dependency authentication section",
            "Fastlane is forbidden": "forbidden delivery tooling",
            "xcode-cloud-mcp": "first-party Xcode Cloud tooling",
            "app-store-connect-mcp": "first-party App Store tooling",
            "required behavior cannot be implemented": "non-Swift capability-gap threshold",
            "missing Swift capability": "documented non-Swift exception",
            "actions/create-github-app-token@v3": "short-lived GitHub App token workflow",
            "client-id:": "current GitHub App client identifier input",
            "permission-contents: read": "read-only private dependency permission",
            "GIT_CONFIG_KEY_0": "process-level Git authentication",
            "GIT_CONFIG_VALUE_0: https://github.com/": "GitHub HTTPS rewrite source",
            "complete subprocess tree as privileged": "credential-bearing subprocess trust boundary",
            "isolated disposable or ephemeral self-hosted runner": "untrusted-code runner isolation",
            "This trust rule is event-independent": "event-independent credential boundary",
            "pull_request_target": "untrusted pull-request credential boundary",
        ]
        for (value, description) in required where !contents.contains(value) {
            errors.append("Guidelines/CICD.md: missing \(description): '\(value)'")
        }
    }
    if let contents = readText(packagesGuideline, errors: &errors) {
        let required = [
            "[external dependency policy](Development.md#external-dependencies)": "package dependency policy pointer",
            "must not introduce or conceal a third-party runtime dependency": "first-party package boundary",
            "guideline-mandated tooling dependency": "DocC tooling exception",
            "root `LICENSE` file": "root license-file retention",
            "Retain the README license badge": "README license-badge retention",
            "do not add a dedicated License heading or license-description section":
                "README license-section prohibition",
        ]
        for (value, description) in required where !contents.contains(value) {
            errors.append("Guidelines/Packages.md: missing \(description): '\(value)'")
        }
    }
    if let contents = readText(agentsTemplate, errors: &errors),
        !contents.contains("BEGIN THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1")
    {
        errors.append("Templates/AGENTS.md: missing external-dependency contract")
    }
}

/// Validates the completion-audit skill and native helper scripts.
func validateAuditSkill(_ errors: inout [String]) {
    guard let contents = readText(auditSkill, errors: &errors) else {
        return
    }
    let required = [
        "name: agent-guidelines-audit": "skill name",
        "before claiming completion": "completion trigger",
        "git diff --check": "diff validation",
        "validate_consumer_setup.swift": "consumer integration validation",
        "format-and-lint": "local Swift-format audit",
        "lint-strict": "strict Swift-format CI audit",
        "AppLogger": "AppLogger integration audit",
        "Logging.md": "shared Logging guide reference",
        "Dependency declaration and target linkage alone": "lifecycle observability coverage audit",
        "## Audit documentation consistency": "documentation drift audit",
        "Known stale documentation blocks completion": "stale documentation stopping rule",
        "## Audit documentation formatting": "documentation formatting audit",
        "check_markdown_wrapping.swift": "Markdown line-wrapping check",
        "existing root Markdown files and declared durable documentation folders":
            "documentation-convention adoption pass",
        "new third-party dependency": "third-party dependency audit",
        "repository-owner approval": "third-party dependency approval gate",
        "no unresolved P0/P1 blocker remains": "Codex review stopping rule",
        "## Audit Xcode project settings": "Xcode project-settings audit",
        "Xcode/ProjectSettings.md": "shared Xcode project-settings guide reference",
        "GCC_TREAT_WARNINGS_AS_ERRORS": "warnings-as-errors project audit",
        "SWIFT_UPCOMING_FEATURE_": "future-facing upcoming-feature audit",
        "SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor": "actor-isolation project audit",
        "SWIFT_VERSION": "Swift language-version project audit",
        "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO": "export-compliance project audit",
        "## Audit App Store metadata": "App Store metadata audit",
        "noOp: true": "App Store remote reconciliation audit",
        "xcodebuild -showBuildSettings": "effective target build-setting inspection",
        "nearest applicable `AGENTS.md`": "project-setting exception lookup",
        "## Audit localization": "localization audit",
        "Guidelines/Localization.md": "shared Localization guide reference",
        "prepare_localizable_symbols.swift": "generated-symbol preparation audit",
        "validate_string_catalogs.swift": "String Catalog validation audit",
        "check_xcstrings_inspection.swift": "String Catalog editor evidence gate",
        "Fail closed when a changed catalog lacks that recorded editor evidence":
            "missing String Catalog editor evidence stopping rule",
        "pull-request description": "durable pull-request evidence summary",
        "A local wrapper may": "consumer localization-wrapper boundary",
        "new repository-owned executable scripts": "native Swift script audit",
        "Templates/.gitignore": "shared gitignore template comparison",
        "# Project-specific: <rationale>": "project-specific gitignore exception marker",
        "git check-ignore -v": "gitignore behavior verification",
        "git ls-files": "tracked-file safety check",
        "CocoaPods or Carthage": "forbidden package-manager audit",
        "Guidelines/CICD.md": "shared CI/CD guide reference",
        "fastlane adoption": "forbidden delivery-tooling audit",
        "missing Swift capability": "non-Swift script exception audit",
        "## Audit Swift package settings": "Swift package-settings audit",
        "Guidelines/Packages.md#compiler-settings-baseline": "shared package compiler-settings guide reference",
        "Package.swift": "package manifest discovery",
        "swift package --package-path <package-root> dump-package": "evaluated manifest inspection",
        "swiftLanguageModes": "package language-mode audit",
        ".treatAllWarnings(as: .error)": "package warnings-as-errors audit",
        ".enableUpcomingFeature(...)": "package upcoming-feature audit",
        "complete strict concurrency as supplied by the language mode": "Swift 6 strict-concurrency handling",
        ".enableUpcomingFeature(\"StrictConcurrency\")": "upcoming StrictConcurrency removal audit",
        ".enableExperimentalFeature(\"StrictConcurrency\")": "experimental StrictConcurrency removal audit",
        "StrictConcurrency=complete": "explicit StrictConcurrency removal audit",
        ".defaultIsolation(MainActor.self)": "default MainActor isolation exclusion",
        "package plug-in targets": "unsupported plug-in target exclusion",
        "package-setting failure": "package-setting exception lookup",
    ]
    for (value, description) in required where !contents.contains(value) {
        errors.append(".agents/skills/agent-guidelines-audit/SKILL.md: missing \(description): '\(value)'")
    }
    for feature in packageUpcomingFeatures where !contents.contains(feature) {
        errors.append(".agents/skills/agent-guidelines-audit/SKILL.md: missing package feature audit '\(feature)'")
    }
    validateExecutable(markdownWrappingScript, description: "Markdown wrapping checker", errors: &errors)
    validateExecutable(stringCatalogInspectionScript, description: "String Catalog inspection checker", errors: &errors)
    if let development = readText(developmentGuideline, errors: &errors),
        !development.contains("$agent-guidelines-audit")
    {
        errors.append("Guidelines/Development.md: missing mandatory $agent-guidelines-audit invocation")
    }
    if let template = readText(agentsTemplate, errors: &errors) {
        let requiredTemplateValues = [
            "AgentGuidelines/Guidelines/Development.md": "Development.md pointer",
            "BEGIN THATFACTORY DOCUMENTATION MAINTENANCE CONTRACT v1": "documentation-maintenance contract",
            "BEGIN THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1": "external-dependency contract",
            "BEGIN THATFACTORY RUNTIME OBSERVABILITY CONTRACT v1": "runtime-observability contract",
            "AgentGuidelines/Guidelines/Documentation.md": "Documentation.md pointer",
            "## Stack": "Stack section",
        ]
        for (value, description) in requiredTemplateValues where !template.contains(value) {
            errors.append("Templates/AGENTS.md: missing \(description)")
        }
    }
}

/// Validates the reusable ignore template and its shared reconciliation policy.
func validateGitignoreGuidance(_ errors: inout [String]) {
    guard let template = readText(gitignoreTemplate, errors: &errors) else { return }
    let activePatterns = template.split(separator: "\n").map(String.init)
    let requiredPatterns = [
        ".DS_Store", "xcuserdata/", "/build/", "/DerivedData/", "/.build/", "/Packages/",
        ".swiftpm/configuration/registries.json", "node_modules/", "dist/", "coverage/", "__pycache__/",
        ".venv/", ".env", "!.env.example", ".netrc", ".appstore-connect-mcp/", ".devspace/",
        "/public-check/",
    ]
    for pattern in requiredPatterns where !activePatterns.contains(pattern) {
        errors.append("Templates/.gitignore: missing required pattern '\(pattern)'")
    }
    for forbidden in ["Package.resolved", "*.xcodeproj", "*.xcworkspace", ".swiftpm/"]
    where activePatterns.contains(forbidden) {
        errors.append("Templates/.gitignore: must not ignore authored or lockfile path '\(forbidden)'")
    }
    for forbiddenPrefix in ["Carthage/", "fastlane/", "Pods/"]
    where activePatterns.contains(where: { $0.hasPrefix(forbiddenPrefix) }) {
        errors.append("Templates/.gitignore: must not include forbidden tooling pattern '\(forbiddenPrefix)'")
    }
    guard let guideline = readText(gitignoreGuideline, errors: &errors) else { return }
    for required in [
        "active `.gitignore` patterns", "# Project-specific: <rationale>", "git check-ignore -v", "git ls-files",
        "Do not remove it or silently accept it",
    ] where !guideline.contains(required) {
        errors.append("Guidelines/Git/IgnoreFiles.md: missing ignore reconciliation policy '\(required)'")
    }
}

/// Runs every repository guideline validation.
func main() -> Int32 {
    var errors: [String] = []
    validateLinks(&errors)
    validateCatalog(&errors)
    validateVersion(&errors)
    validateReadmeContract(&errors)
    validatePublicContent(&errors)
    validateSwiftFormatConfiguration(&errors)
    validateEditorConfiguration(&errors)
    validateExecutable(swiftFormatScript, description: "Swift-format script", errors: &errors)
    validateScriptLanguages(&errors)
    validateSwiftFormatGuideline(&errors)
    validateDocumentationGuideline(&errors)
    validateLocalizationGuideline(&errors)
    validateAppStoreGuideline(&errors)
    validateLocalizationScripts(&errors)
    validateXcodeProjectSettingsGuideline(&errors)
    validatePackageCompilerSettingsGuideline(&errors)
    validateExternalDependencyPolicy(&errors)
    validateGitignoreGuidance(&errors)
    validateExecutable(consumerSetupScript, description: "consumer setup validator", errors: &errors)
    validateAuditSkill(&errors)
    if !errors.isEmpty {
        print("Guideline validation failed:")
        for error in errors { print("- \(error)") }
        return 1
    }
    let guideRoot = root.appendingPathComponent("Guidelines")
    let guideCount = recursiveFiles(below: guideRoot).filter { $0.pathExtension.lowercased() == "md" }.count
    let version =
        (try? String(contentsOf: versionFile, encoding: .utf8))?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
    print("Validated \(guideCount) guidelines for version \(version).")
    return 0
}

exit(main())
