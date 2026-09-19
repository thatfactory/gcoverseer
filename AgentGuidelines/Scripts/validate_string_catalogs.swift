#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// One normalized printf placeholder.
struct FormatToken: Hashable {
    let position: Int
    let name: String?
    let format: String
}

/// Parsed validation command-line values.
struct Arguments {
    var catalogDirectories: [String] = []
    var sourceDirectories: [String] = []
    var symbolCatalogs: [String] = []
    var requiredLanguages: Set<String> = []
}

let formatSpecifierPattern =
    #"%(?!%)(?:([1-9]\d*)\$)?(?:\(([A-Za-z_][A-Za-z0-9_]*)\))?([-+ #0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|z|t|j)?[diouxXfFeEgGaAcCsSp@])"#

/// Returns one capture from a regular-expression match.
func capture(_ index: Int, from match: NSTextCheckingResult, in value: String) -> String? {
    let range = match.range(at: index)
    guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else {
        return nil
    }
    return String(value[swiftRange])
}

/// Returns position, semantic name, and type for every printf placeholder.
func formatSignature(_ value: String) -> [FormatToken] {
    guard let expression = try? NSRegularExpression(pattern: formatSpecifierPattern) else {
        return []
    }
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    var implicitPosition = 1
    let tokens = expression.matches(in: value, range: range).map { match -> FormatToken in
        defer { implicitPosition += 1 }
        let position = capture(1, from: match, in: value).flatMap(Int.init) ?? implicitPosition
        return FormatToken(
            position: position,
            name: capture(2, from: match, in: value),
            format: capture(3, from: match, in: value) ?? ""
        )
    }
    return tokens.sorted {
        ($0.position, $0.name ?? "", $0.format) < ($1.position, $1.name ?? "", $1.format)
    }
}

/// Returns every leaf String Catalog value below one localization.
func stringUnitValues(_ value: Any) -> [String] {
    if let dictionary = value as? [String: Any] {
        var values: [String] = []
        if let stringUnit = dictionary["stringUnit"] as? [String: Any],
            let stringValue = stringUnit["value"] as? String
        {
            values.append(stringValue)
        }
        for (key, child) in dictionary where key != "stringUnit" {
            values.append(contentsOf: stringUnitValues(child))
        }
        return values
    }
    if let array = value as? [Any] {
        return array.flatMap(stringUnitValues)
    }
    return []
}

/// Returns every leaf String Catalog state below one localization.
func stringUnitStates(_ value: Any) -> [String] {
    if let dictionary = value as? [String: Any] {
        var states: [String] = []
        if let stringUnit = dictionary["stringUnit"] as? [String: Any],
            let state = stringUnit["state"] as? String
        {
            states.append(state)
        }
        for (key, child) in dictionary where key != "stringUnit" {
            states.append(contentsOf: stringUnitStates(child))
        }
        return states
    }
    if let array = value as? [Any] {
        return array.flatMap(stringUnitStates)
    }
    return []
}

/// Renders a normalized placeholder signature for diagnostics.
func displaySignature(_ signature: [FormatToken]) -> String {
    let specifiers = signature.map { "%" + ($0.name.map { "(\($0))" } ?? "") + $0.format }
    return specifiers.isEmpty ? "none" : specifiers.joined(separator: ", ")
}

/// Returns translated values whose placeholder signature differs from source.
func formatSignatureIssues(_ catalog: [String: Any]) -> [String] {
    guard let sourceLanguage = catalog["sourceLanguage"] as? String,
        let strings = catalog["strings"] as? [String: Any]
    else {
        return ["catalog structure is invalid"]
    }
    var issues: [String] = []
    for key in strings.keys.sorted() {
        guard let entry = strings[key] as? [String: Any],
            entry["extractionState"] as? String != "stale",
            let localizations = entry["localizations"] as? [String: Any]
        else {
            continue
        }
        let sourceSignatures = Set(stringUnitValues(localizations[sourceLanguage] as Any).map(formatSignature))
        guard sourceSignatures.count == 1, let expected = sourceSignatures.first else {
            issues.append("\(key): source variants have inconsistent format specifiers")
            continue
        }
        for language in localizations.keys.sorted() where language != sourceLanguage {
            for value in stringUnitValues(localizations[language] as Any) {
                let actual = formatSignature(value)
                if actual != expected {
                    issues.append(
                        "\(key) [\(language)]: format specifiers \(displaySignature(actual)) "
                            + "do not match \(displaySignature(expected))"
                    )
                }
            }
        }
    }
    return issues
}

/// Returns missing required localizations and unfinished translated values.
func translationStateIssues(_ catalog: [String: Any], requiredLanguages: Set<String>) -> [String] {
    guard let sourceLanguage = catalog["sourceLanguage"] as? String,
        let strings = catalog["strings"] as? [String: Any]
    else {
        return ["catalog structure is invalid"]
    }
    var issues: [String] = []
    for key in strings.keys.sorted() {
        guard let entry = strings[key] as? [String: Any], entry["extractionState"] as? String != "stale" else {
            continue
        }
        let localizations = entry["localizations"] as? [String: Any] ?? [:]
        for language in requiredLanguages.subtracting([sourceLanguage]).sorted() where localizations[language] == nil {
            issues.append("\(key) [\(language)]: required localization is missing")
        }
        for language in localizations.keys.sorted() where language != sourceLanguage {
            let states = stringUnitStates(localizations[language] as Any)
            if states.isEmpty {
                issues.append("\(key) [\(language)]: localization has no string units")
                continue
            }
            let unfinished = Set(states.filter { $0 == "new" || $0 == "needs_review" }).sorted()
            if !unfinished.isEmpty {
                issues.append("\(key) [\(language)]: unfinished states \(unfinished.joined(separator: ", "))")
            }
        }
    }
    return issues
}

/// Returns active catalog entries that cannot generate expected Swift symbols.
func symbolIssues(_ catalog: [String: Any]) -> [String] {
    guard let sourceLanguage = catalog["sourceLanguage"] as? String,
        let strings = catalog["strings"] as? [String: Any]
    else {
        return ["catalog structure is invalid"]
    }
    var issues: [String] = []
    for key in strings.keys.sorted() {
        guard let entry = strings[key] as? [String: Any] else {
            issues.append("\(key): entry is not a dictionary")
            continue
        }
        if entry["extractionState"] as? String == "stale" {
            continue
        }
        if entry["extractionState"] as? String != "manual" {
            issues.append("\(key): extractionState is not manual")
        }
        let localizations = entry["localizations"] as? [String: Any]
        if localizations?[sourceLanguage] as? [String: Any] == nil {
            issues.append("\(key): source localization \(sourceLanguage) is missing")
        }
    }
    return issues
}

/// Recursively discovers files with an extension below a directory.
func files(withExtension pathExtension: String, below directories: [String]) -> [String] {
    let fileManager = FileManager.default
    var paths = Set<String>()
    for directory in directories {
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            continue
        }
        for case let candidate as String in enumerator where candidate.hasSuffix(".\(pathExtension)") {
            let path = URL(fileURLWithPath: directory).appendingPathComponent(candidate).standardizedFileURL.path
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue {
                paths.insert(path)
            }
        }
    }
    return paths.sorted()
}

/// Runs a process and returns its standard output.
func run(_ command: [String]) throws -> Data {
    let process = Process()
    let output = Pipe()
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
            ?? "xcstringstool extract failed"
        throw NSError(
            domain: "CatalogValidation", code: Int(process.terminationStatus),
            userInfo: [
                NSLocalizedDescriptionKey: detail
            ])
    }
    return outputData
}

/// Returns checked-in Swift locations that still use localization literals.
func literalLocalizationReferences(sourceDirectories: [String]) throws -> [String] {
    let sourcePaths = files(withExtension: "swift", below: sourceDirectories)
    if sourcePaths.isEmpty {
        return []
    }
    let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporary) }
    _ = try run(
        [
            "xcrun", "xcstringstool", "extract", "--modern-localizable-strings", "--SwiftUI",
            "--omit-empty-stringsdata", "--output-directory", temporary.path,
        ] + sourcePaths
    )
    let stringsDataPaths = files(withExtension: "stringsdata", below: [temporary.path])
    var references: [String] = []
    for path in stringsDataPaths {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let stringsData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            continue
        }
        let source = stringsData["source"] as? String ?? URL(fileURLWithPath: path).lastPathComponent
        let tables = stringsData["tables"] as? [String: Any]
        let entries = tables?["Localizable"] as? [[String: Any]] ?? []
        for entry in entries {
            let location = entry["location"] as? [String: Any]
            let line: String
            if let number = location?["startingLine"] as? NSNumber {
                line = number.stringValue
            } else {
                line = "?"
            }
            let key = entry["key"] as? String ?? "<unknown>"
            references.append("\(source):\(line): \(key)")
        }
    }
    return references.sorted()
}

/// Parses validation command-line arguments.
func parseArguments(_ values: [String]) throws -> Arguments {
    var arguments = Arguments()
    var index = 0
    while index < values.count {
        let value = values[index]
        if value == "--help" {
            print(
                "Usage: validate_string_catalogs.swift --catalog-directory <path> "
                    + "--source-directory <path> [--symbol-catalog <path>] "
                    + "[--required-language <identifier>]"
            )
            exit(0)
        }
        guard index + 1 < values.count else {
            throw NSError(
                domain: "CatalogValidation", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "missing value for \(value)"
                ])
        }
        let next = values[index + 1]
        switch value {
        case "--catalog-directory": arguments.catalogDirectories.append(next)
        case "--source-directory": arguments.sourceDirectories.append(next)
        case "--symbol-catalog": arguments.symbolCatalogs.append(URL(fileURLWithPath: next).standardizedFileURL.path)
        case "--required-language": arguments.requiredLanguages.insert(next)
        default:
            throw NSError(
                domain: "CatalogValidation", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "unknown argument: \(value)"
                ])
        }
        index += 2
    }
    guard !arguments.catalogDirectories.isEmpty, !arguments.sourceDirectories.isEmpty else {
        throw NSError(
            domain: "CatalogValidation", code: 2,
            userInfo: [
                NSLocalizedDescriptionKey: "--catalog-directory and --source-directory are required"
            ])
    }
    return arguments
}

/// Writes text to standard error.
func writeError(_ value: String) {
    FileHandle.standardError.write(Data((value + "\n").utf8))
}

/// Validates configured catalogs and Swift source directories.
func main() -> Int32 {
    do {
        let arguments = try parseArguments(Array(CommandLine.arguments.dropFirst()))
        let catalogPaths = files(withExtension: "xcstrings", below: arguments.catalogDirectories)
        guard !catalogPaths.isEmpty else {
            writeError("No String Catalogs found in the configured directories.")
            return 1
        }
        let catalogSet = Set(catalogPaths)
        let symbolCatalogs =
            arguments.symbolCatalogs.isEmpty
            ? Set(catalogPaths.filter { URL(fileURLWithPath: $0).lastPathComponent == "Localizable.xcstrings" })
            : Set(arguments.symbolCatalogs)
        let unknownSymbolCatalogs = symbolCatalogs.subtracting(catalogSet)
        if !unknownSymbolCatalogs.isEmpty {
            for path in unknownSymbolCatalogs.sorted() {
                writeError("\(path): generated-symbol catalog is outside the configured catalogs.")
            }
            return 1
        }
        var failed = false
        for catalogPath in catalogPaths {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: catalogPath))
                guard let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let strings = catalog["strings"] as? [String: Any]
                else {
                    writeError("\(catalogPath): catalog has no strings dictionary.")
                    failed = true
                    continue
                }
                let staleKeys = strings.keys.filter {
                    (strings[$0] as? [String: Any])?["extractionState"] as? String == "stale"
                }.sorted()
                if !staleKeys.isEmpty {
                    failed = true
                    writeError("\(catalogPath): stale extracted strings:")
                    for key in staleKeys { writeError("  - \(key)") }
                }
                if symbolCatalogs.contains(catalogPath) {
                    let issues = symbolIssues(catalog)
                    if !issues.isEmpty {
                        failed = true
                        writeError("\(catalogPath): entries that are not symbol-ready:")
                        for issue in issues { writeError("  - \(issue)") }
                    }
                }
                let formatIssues = formatSignatureIssues(catalog)
                if !formatIssues.isEmpty {
                    failed = true
                    writeError("\(catalogPath): format-specifier mismatches:")
                    for issue in formatIssues { writeError("  - \(issue)") }
                }
                let stateIssues = translationStateIssues(catalog, requiredLanguages: arguments.requiredLanguages)
                if !stateIssues.isEmpty {
                    failed = true
                    writeError("\(catalogPath): localization-state issues:")
                    for issue in stateIssues { writeError("  - \(issue)") }
                }
            } catch {
                writeError("\(catalogPath): \(error.localizedDescription)")
                failed = true
            }
        }
        do {
            let references = try literalLocalizationReferences(sourceDirectories: arguments.sourceDirectories)
            if !references.isEmpty {
                failed = true
                writeError("Checked-in Swift localization literals must use generated symbols:")
                for reference in references { writeError("  - \(reference)") }
            }
        } catch {
            writeError("Could not validate Swift localization literals: \(error.localizedDescription)")
            return 1
        }
        if failed {
            writeError(
                "Prepare generated-symbol catalogs, migrate reported Swift literals, and resolve catalog issues."
            )
            return 1
        }
        print("String Catalog validation passed: symbols, states, format signatures, and Swift source are valid.")
        return 0
    } catch {
        writeError("String Catalog validation failed: \(error.localizedDescription)")
        return 2
    }
}

exit(main())
