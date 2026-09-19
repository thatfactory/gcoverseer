#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

/// A prose block that should occupy one physical line.
struct Finding {
    let path: String
    let start: Int
    let end: Int
    let kind: String
}

/// A candidate prose block being assembled.
struct Block {
    let kind: String
    let start: Int
    var end: Int
}

let fencePattern = #"^\s*(`{3,}|~{3,})"#
let headingPattern = #"^\s{0,3}#{1,6}(?:\s|$)"#
let listItemPattern = #"^(\s{0,3})(?:[-+*]|\d+[.)])\s+(.*)$"#
let linkDefinitionPattern = #"^\s{0,3}\[[^]]+\]:\s*\S+"#
let thematicBreakPattern = #"^\s{0,3}(?:(?:\*\s*){3,}|(?:-\s*){3,}|(?:_\s*){3,})$"#
let setextUnderlinePattern = #"^\s{0,3}(?:=+|-+)\s*$"#
let tableDelimiterPattern = #"^\s*\|?(?:\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?\s*$"#
let quotePattern = #"^\s{0,3}>\s?"#
let alertMarkerPattern = #"^\[!(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]$"#

/// Returns the first regular-expression match in a string.
func firstMatch(_ pattern: String, in value: String) -> NSTextCheckingResult? {
    let expression = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    return expression?.firstMatch(in: value, range: range)
}

/// Returns one capture from a regular-expression match.
func capture(_ index: Int, from match: NSTextCheckingResult, in value: String) -> String? {
    let range = match.range(at: index)
    guard range.location != NSNotFound, let swiftRange = Range(range, in: value) else {
        return nil
    }
    return String(value[swiftRange])
}

/// Returns whether a line has the shape of a Markdown table row.
func isTableRow(_ line: String) -> Bool {
    let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
    return firstMatch(tableDelimiterPattern, in: stripped) != nil
        || (stripped.hasPrefix("|") && stripped.hasSuffix("|"))
}

/// Returns whether a line should terminate prose-block detection.
func isVerbatimOrStructure(_ line: String) -> Bool {
    let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
    return stripped.isEmpty
        || firstMatch(headingPattern, in: line) != nil
        || firstMatch(thematicBreakPattern, in: line) != nil
        || firstMatch(setextUnderlinePattern, in: line) != nil
        || firstMatch(linkDefinitionPattern, in: line) != nil
        || firstMatch(listItemPattern, in: line) != nil
        || isTableRow(line)
        || line.hasPrefix("    ")
        || stripped.hasPrefix("<")
}

/// Expands file and directory arguments into unique Markdown files.
func markdownFiles(_ paths: [String]) throws -> [String] {
    let fileManager = FileManager.default
    var files = Set<String>()
    for path in paths {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw NSError(
                domain: "MarkdownWrapping", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "path does not exist: \(path)"
                ])
        }
        if isDirectory.boolValue {
            guard let enumerator = fileManager.enumerator(atPath: path) else {
                continue
            }
            for case let candidate as String in enumerator where candidate.lowercased().hasSuffix(".md") {
                let fullPath = URL(fileURLWithPath: path).appendingPathComponent(candidate).path
                var candidateIsDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: fullPath, isDirectory: &candidateIsDirectory),
                    !candidateIsDirectory.boolValue
                {
                    files.insert(fullPath)
                }
            }
        } else if URL(fileURLWithPath: path).pathExtension.lowercased() == "md" {
            files.insert(path)
        }
    }
    return files.sorted()
}

/// Finds prose blocks that span multiple physical lines in one Markdown file.
func findings(for path: String) throws -> [Finding] {
    let contents = try String(contentsOfFile: path, encoding: .utf8)
    let lines = contents.components(separatedBy: .newlines)
    var findings: [Finding] = []
    var block: Block?
    var fenceMarker: Character?
    var inComment = false
    var inFrontmatter = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
    var previousQuoteDepth = 0

    func finishBlock() {
        if let block, block.end > block.start {
            findings.append(Finding(path: path, start: block.start, end: block.end, kind: block.kind))
        }
        block = nil
    }

    for (offset, line) in lines.enumerated() {
        let lineNumber = offset + 1
        let stripped = line.trimmingCharacters(in: .whitespacesAndNewlines)
        var quoteDepth = 0
        var quoteContent = line
        while let match = firstMatch(quotePattern, in: quoteContent),
            let range = Range(match.range, in: quoteContent)
        {
            quoteContent.removeSubrange(range)
            quoteDepth += 1
        }
        defer {
            previousQuoteDepth = quoteDepth
        }

        if inFrontmatter {
            if lineNumber > 1, stripped == "---" {
                inFrontmatter = false
            }
            continue
        }

        if let match = firstMatch(fencePattern, in: line), let marker = capture(1, from: match, in: line)?.first {
            if fenceMarker == nil {
                finishBlock()
                fenceMarker = marker
            } else if fenceMarker == marker {
                fenceMarker = nil
            }
            continue
        }
        if fenceMarker != nil {
            continue
        }

        if inComment {
            if line.contains("-->") {
                inComment = false
            }
            continue
        }
        if line.contains("<!--") {
            finishBlock()
            if !line.components(separatedBy: "<!--").dropFirst().joined(separator: "<!--").contains("-->") {
                inComment = true
            }
            continue
        }

        if quoteDepth > 0 {
            let trimmedQuoteContent = quoteContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if quoteDepth == 1, previousQuoteDepth == 0,
                firstMatch(alertMarkerPattern, in: trimmedQuoteContent) != nil
            {
                finishBlock()
                continue
            }
            if isVerbatimOrStructure(quoteContent) {
                finishBlock()
                continue
            }
            let kind = "block quote (depth \(quoteDepth))"
            if block?.kind == kind {
                block?.end = lineNumber
            } else {
                finishBlock()
                block = Block(kind: kind, start: lineNumber, end: lineNumber)
            }
            continue
        }

        if let match = firstMatch(listItemPattern, in: line) {
            finishBlock()
            let content = capture(2, from: match, in: line) ?? ""
            if !content.isEmpty, !isVerbatimOrStructure(content) {
                block = Block(kind: "list item", start: lineNumber, end: lineNumber)
            }
            continue
        }

        if block?.kind == "list item", line.hasPrefix("  ") || line.hasPrefix("\t") {
            if isVerbatimOrStructure(line.trimmingCharacters(in: .whitespaces)) {
                finishBlock()
            } else {
                block?.end = lineNumber
            }
            continue
        }

        if isVerbatimOrStructure(line) {
            finishBlock()
            continue
        }

        if block?.kind == "paragraph" {
            block?.end = lineNumber
        } else {
            finishBlock()
            block = Block(kind: "paragraph", start: lineNumber, end: lineNumber)
        }
    }
    finishBlock()
    return findings
}

/// Writes text to standard error.
func writeError(_ value: String) {
    FileHandle.standardError.write(Data((value + "\n").utf8))
}

/// Runs the wrapping audit and returns a lint-style status code.
func main() -> Int32 {
    let paths = Array(CommandLine.arguments.dropFirst())
    if paths.isEmpty || paths.contains("--help") {
        print("Usage: check_markdown_wrapping.swift <Markdown files or folders...>")
        return paths.isEmpty ? 2 : 0
    }
    do {
        let files = try markdownFiles(paths)
        let allFindings = try files.flatMap { try findings(for: $0) }
        for finding in allFindings {
            print(
                "\(finding.path):\(finding.start): \(finding.kind) spans physical lines "
                    + "\(finding.start)-\(finding.end); keep its prose on one line"
            )
        }
        if !allFindings.isEmpty {
            writeError("Found \(allFindings.count) hard-wrapped Markdown prose block(s).")
            return 1
        }
        print("Checked \(files.count) Markdown file(s); no hard-wrapped prose found.")
        return 0
    } catch {
        writeError("Markdown wrapping audit failed: \(error.localizedDescription)")
        return 2
    }
}

exit(main())
