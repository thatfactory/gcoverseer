#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// Marks every source-language string unit in a localization as translated.
func markStringUnitsTranslated(_ value: Any) -> Any {
    if var dictionary = value as? [String: Any] {
        if var stringUnit = dictionary["stringUnit"] as? [String: Any] {
            stringUnit["state"] = "translated"
            dictionary["stringUnit"] = stringUnit
        }
        for (key, child) in dictionary {
            dictionary[key] = markStringUnitsTranslated(child)
        }
        return dictionary
    }
    if let array = value as? [Any] {
        return array.map(markStringUnitsTranslated)
    }
    return value
}

/// Returns one symbol-ready entry while preserving comments and translations.
func prepareEntry(key: String, entry: [String: Any], sourceLanguage: String) throws -> [String: Any] {
    if entry["extractionState"] as? String == "stale" {
        return entry
    }
    var localizations = entry["localizations"] as? [String: Any] ?? [:]
    if let sourceLocalization = localizations[sourceLanguage] as? [String: Any] {
        localizations[sourceLanguage] = markStringUnitsTranslated(sourceLocalization)
    } else {
        if entry["extractionState"] as? String == "manual" {
            throw NSError(
                domain: "SymbolPreparation", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "\(key): manual entry has no \(sourceLanguage) source value"
                ])
        }
        localizations[sourceLanguage] = [
            "stringUnit": [
                "state": "translated",
                "value": key,
            ]
        ]
    }
    var prepared = entry
    prepared["extractionState"] = "manual"
    prepared["localizations"] = localizations
    return prepared
}

/// Returns a catalog whose active entries generate localized Swift symbols.
func prepareCatalog(_ catalog: [String: Any]) throws -> [String: Any] {
    guard let sourceLanguage = catalog["sourceLanguage"] as? String, !sourceLanguage.isEmpty else {
        throw NSError(
            domain: "SymbolPreparation", code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "catalog has no sourceLanguage"
            ])
    }
    guard let strings = catalog["strings"] as? [String: Any] else {
        throw NSError(
            domain: "SymbolPreparation", code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "catalog has no strings dictionary"
            ])
    }
    var preparedStrings: [String: Any] = [:]
    for key in strings.keys.sorted() {
        guard let entry = strings[key] as? [String: Any] else {
            throw NSError(
                domain: "SymbolPreparation", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "catalog contains a non-dictionary string entry"
                ])
        }
        preparedStrings[key] = try prepareEntry(key: key, entry: entry, sourceLanguage: sourceLanguage)
    }
    var prepared = catalog
    prepared["strings"] = preparedStrings
    return prepared
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

/// Renders a JSON string scalar.
func renderJSONString(_ value: String) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: [value])
    let rendered = String(data: data, encoding: .utf8) ?? "[]"
    return String(rendered.dropFirst().dropLast())
}

/// Renders JSON with deterministic Xcode-style spacing.
func renderJSON(_ value: Any, indentation: Int = 0) throws -> String {
    if let dictionary = value as? [String: Any] {
        if dictionary.isEmpty {
            return "{}"
        }
        let keys = dictionary.keys.sorted()
        var lines = ["{"]
        for (index, key) in keys.enumerated() {
            guard let child = dictionary[key] else {
                continue
            }
            var rendered = try renderJSON(child, indentation: indentation + 2).components(separatedBy: "\n")
            let prefix = String(repeating: " ", count: indentation + 2) + (try renderJSONString(key)) + " : "
            rendered[0] = prefix + rendered[0]
            if index < keys.count - 1 {
                rendered[rendered.count - 1] += ","
            }
            lines.append(contentsOf: rendered)
        }
        lines.append(String(repeating: " ", count: indentation) + "}")
        return lines.joined(separator: "\n")
    }
    if let array = value as? [Any] {
        if array.isEmpty {
            return "[]"
        }
        var lines = ["["]
        for (index, child) in array.enumerated() {
            var rendered = try renderJSON(child, indentation: indentation + 2).components(separatedBy: "\n")
            rendered[0] = String(repeating: " ", count: indentation + 2) + rendered[0]
            if index < array.count - 1 {
                rendered[rendered.count - 1] += ","
            }
            lines.append(contentsOf: rendered)
        }
        lines.append(String(repeating: " ", count: indentation) + "]")
        return lines.joined(separator: "\n")
    }
    let data = try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
    guard let rendered = String(data: data, encoding: .utf8) else {
        throw NSError(
            domain: "SymbolPreparation", code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "could not render JSON value"
            ])
    }
    return rendered
}

/// Returns whether two JSON objects are semantically equal.
func jsonObjectsEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    (lhs as AnyObject).isEqual(rhs)
}

/// Writes text to standard error.
func writeError(_ value: String) {
    FileHandle.standardError.write(Data((value + "\n").utf8))
}

/// Prepares explicit catalogs in place or checks whether preparation is needed.
func main() -> Int32 {
    var checkOnly = false
    var catalogs: [String] = []
    for argument in CommandLine.arguments.dropFirst() {
        if argument == "--check" {
            checkOnly = true
        } else if argument == "--help" {
            print("Usage: prepare_localizable_symbols.swift <catalogs...> [--check]")
            return 0
        } else if argument.hasPrefix("-") {
            writeError("Unknown argument: \(argument)")
            return 2
        } else {
            catalogs.append(argument)
        }
    }
    guard !catalogs.isEmpty else {
        writeError("At least one String Catalog path is required.")
        return 2
    }
    var failed = false
    for path in catalogs {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            guard let catalog = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NSError(
                    domain: "SymbolPreparation", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "catalog root is not a dictionary"
                    ])
            }
            let prepared = try prepareCatalog(catalog)
            if jsonObjectsEqual(prepared, catalog) {
                print("\(path): already symbol-ready.")
                continue
            }
            if checkOnly {
                writeError("\(path): run this script without --check to prepare generated symbols.")
                failed = true
                continue
            }
            try (renderJSON(prepared) + "\n").write(toFile: path, atomically: true, encoding: .utf8)
            let count = (prepared["strings"] as? [String: Any])?.count ?? 0
            print("\(path): prepared \(count) generated symbols.")
        } catch {
            writeError("\(path): \(error.localizedDescription)")
            failed = true
        }
    }
    return failed ? 1 : 0
}

exit(main())
