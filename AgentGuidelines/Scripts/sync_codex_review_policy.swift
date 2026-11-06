#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

// MARK: - Policy identity

/// The only production source of published policy text.
let policyRepository = "https://github.com/thatfactory/agent-guidelines.git"
let scriptRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let families = ["CODE REVIEW", "PR LIFECYCLE"]
let provenancePrefix = "<!-- THATFACTORY CODEX REVIEW POLICY "

/// An actionable validation or synchronization failure.
struct PolicyError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

/// Explicit command inputs; remote policy text never controls executable code or paths.
struct Options {
    var mode = "check"
    var roots: [URL] = []
    var profile: String?
    var localSource: URL?
    var repository = policyRepository
    var agentsFile = "AGENTS.md"
}

/// One immutable source selected once for an entire invocation.
struct Snapshot {
    let revision: Int
    let commit: String
    let blocks: [String]
}

/// A marked region, including its byte-preserving string range.
struct Region {
    let range: Range<String.Index>
    let text: String
}

/// Runs a process without shell interpolation, draining output before waiting.
func command(_ arguments: [String], at directory: URL? = nil) throws -> String {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    process.currentDirectoryURL = directory
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let bytes = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let value = String(decoding: bytes, as: UTF8.self)
    guard process.terminationStatus == 0 else {
        throw PolicyError(
            "\(arguments.first ?? "command") failed (\(process.terminationStatus)): \(value.trimmingCharacters(in: .whitespacesAndNewlines))"
        )
    }
    return value.trimmingCharacters(in: .newlines)
}

/// Returns regex matches as Swift string ranges.
func regions(_ pattern: String, in text: String) throws -> [Region] {
    let expression = try NSRegularExpression(pattern: pattern)
    return expression.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)).compactMap {
        guard let range = Range($0.range, in: text) else { return nil }
        return Region(range: range, text: String(text[range]))
    }
}

/// Extracts complete contracts and refuses malformed or mismatched marker pairs.
func contracts(_ text: String, family: String) throws -> [Region] {
    let escaped = NSRegularExpression.escapedPattern(for: family)
    let prefix = "THATFACTORY \(escaped) CONTRACT"
    let begins = try regions("<!-- BEGIN \(prefix) v[0-9]+ -->", in: text)
    let ends = try regions("<!-- END \(prefix) v[0-9]+ -->", in: text)
    let blocks = try regions("<!-- BEGIN \(prefix) v([0-9]+) -->[\\s\\S]*?<!-- END \(prefix) v\\1 -->", in: text)
    guard begins.count == ends.count, begins.count == blocks.count,
        text.components(separatedBy: "<!-- BEGIN THATFACTORY \(family) CONTRACT").count - 1 == blocks.count,
        text.components(separatedBy: "<!-- END THATFACTORY \(family) CONTRACT").count - 1 == blocks.count
    else {
        throw PolicyError(
            "malformed \(family.lowercased()) contract markers; repair unmatched or mismatched markers first")
    }
    return blocks
}

/// Reads one canonical policy without importing any executable content.
func snapshot(read: (String) throws -> String, commit: String) throws -> Snapshot {
    let version = try read("ReviewPolicy/VERSION").trimmingCharacters(in: .whitespacesAndNewlines)
    guard let revision = Int(version), revision > 0 else { throw PolicyError("invalid review-policy revision") }
    let policy = try read("ReviewPolicy/Policy.md")
    let blocks = try families.map { family in
        let values = try contracts(policy, family: family)
        guard values.count == 1 else {
            throw PolicyError("canonical policy must contain exactly one \(family.lowercased()) contract")
        }
        return values[0].text
    }
    return Snapshot(revision: revision, commit: commit, blocks: blocks)
}

/// Resolves the highest published revision once and verifies the fetched tag object.
func publishedSnapshot(repository: String) throws -> Snapshot {
    let listing = try command(["git", "ls-remote", "--tags", "--refs", repository, "refs/tags/codex-review-v*"])
    let candidates = listing.split(separator: "\n").compactMap { line -> (Int, String, String)? in
        let fields = line.split(whereSeparator: \.isWhitespace).map(String.init)
        guard fields.count == 2, fields[1].hasPrefix("refs/tags/codex-review-v"),
            let revision = Int(fields[1].dropFirst("refs/tags/codex-review-v".count)), revision > 0
        else { return nil }
        return (revision, fields[0], fields[1])
    }
    guard let selected = candidates.max(by: { $0.0 < $1.0 }) else {
        throw PolicyError("cannot verify latest policy: no published codex-review-vN tag")
    }
    let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("codex-policy-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temporary) }
    _ = try command(["git", "init", "--quiet", temporary.path])
    _ = try command(["git", "fetch", "--quiet", "--no-tags", "--depth=1", repository, selected.2], at: temporary)
    let object = try command(["git", "rev-parse", "FETCH_HEAD"], at: temporary)
    guard object == selected.1 else {
        throw PolicyError("policy tag changed during resolution; refuse uncertain provenance")
    }
    let commit = try command(["git", "rev-parse", "FETCH_HEAD^{commit}"], at: temporary)
    let result = try snapshot(
        read: { path in
            try command(["git", "show", "\(commit):\(path)"], at: temporary)
        }, commit: commit)
    guard result.revision == selected.0 else { throw PolicyError("policy tag and canonical revision disagree") }
    return result
}

/// Selects an immutable published snapshot, or an explicitly local central-development source.
func loadSnapshot(_ options: Options) throws -> Snapshot {
    if let root = options.localSource {
        guard ["central", "template"].contains(options.profile ?? "") else {
            throw PolicyError("--local-source is restricted to the central and template development profiles")
        }
        return try snapshot(
            read: { path in
                try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
            }, commit: "local")
    }
    return try publishedSnapshot(repository: options.repository)
}

/// Returns a profile derived from the actual consumer shape, never from untrusted metadata.
func profile(for root: URL, options: Options) throws -> String {
    let inferred =
        FileManager.default.fileExists(atPath: root.appendingPathComponent("AgentGuidelines").path)
        ? "full" : "review-only"
    let value = options.profile ?? inferred
    guard ["full", "review-only", "central", "template"].contains(value) else {
        throw PolicyError("unknown profile: \(value)")
    }
    if ["central", "template"].contains(value) {
        guard options.localSource != nil else { throw PolicyError("owned development profiles require --local-source") }
    } else {
        guard value == inferred else {
            throw PolicyError("profile \(value) disagrees with repository shape (\(inferred))")
        }
        guard options.agentsFile == "AGENTS.md" else {
            throw PolicyError("consumer policies must live in root AGENTS.md")
        }
    }
    return value
}

/// Produces provenance separately from the identical, self-contained managed contracts.
func provenance(_ snapshot: Snapshot, profile: String) -> String {
    "\(provenancePrefix)profile=\(profile) revision=\(snapshot.revision) source=\(snapshot.commit) -->"
}

/// Validates exact content, policy freshness, profile, and immutable source identity.
func check(_ text: String, snapshot: Snapshot, profile: String) throws {
    let metadata = try regions("<!-- THATFACTORY CODEX REVIEW POLICY [^\\r\\n]*?-->", in: text)
    guard metadata.count == 1, text.components(separatedBy: provenancePrefix).count - 1 == 1,
        metadata[0].text == provenance(snapshot, profile: profile)
    else {
        throw PolicyError(
            "missing, outdated, duplicated, or incorrect review-policy provenance; expected \(provenance(snapshot, profile: profile))"
        )
    }
    for (index, family) in families.enumerated() {
        let actual = try contracts(text, family: family)
        guard actual.count == 1, actual[0].text == snapshot.blocks[index] else {
            throw PolicyError("missing, obsolete, duplicated, or modified \(family.lowercased()) contract")
        }
    }
}

/// Replaces only complete managed regions, preserving every byte of local instructions.
func updated(_ text: String, snapshot: Snapshot, profile: String) throws -> String {
    if (try? check(text, snapshot: snapshot, profile: profile)) != nil { return text }
    var managed = try families.flatMap { try contracts(text, family: $0) }
    managed += try regions("<!-- THATFACTORY CODEX REVIEW POLICY [^\\r\\n]*?-->", in: text)
    let payload = provenance(snapshot, profile: profile) + "\n" + snapshot.blocks.joined(separator: "\n\n")
    guard !managed.isEmpty else { return text + (text.hasSuffix("\n\n") ? "" : "\n\n") + payload + "\n" }
    managed.sort { $0.range.lowerBound < $1.range.lowerBound }
    var result = ""
    var cursor = text.startIndex
    for (index, region) in managed.enumerated() {
        guard region.range.lowerBound >= cursor else { throw PolicyError("overlapping managed regions") }
        result += text[cursor..<region.range.lowerBound]
        if index == 0 { result += payload }
        cursor = region.range.upperBound
    }
    result += text[cursor...]
    try check(result, snapshot: snapshot, profile: profile)
    return result
}

/// Parses the synchronization command without inferring permission to update files.
func parse(_ values: [String]) throws -> Options {
    var result = Options()
    guard let mode = values.first, ["check", "update"].contains(mode) else {
        throw PolicyError(
            "Usage: sync_codex_review_policy.swift check|update [--consumer-root <path>] [--profile full|review-only] [--local-source <central-root> --profile central|template] [--agents-file <relative-path>] [--policy-repository <test-fixture>]"
        )
    }
    result.mode = mode
    var index = 1
    while index < values.count {
        guard index + 1 < values.count else { throw PolicyError("missing value for \(values[index])") }
        let value = values[index + 1]
        switch values[index] {
        case "--consumer-root": result.roots.append(URL(fileURLWithPath: value).standardizedFileURL)
        case "--profile": result.profile = value
        case "--local-source": result.localSource = URL(fileURLWithPath: value).standardizedFileURL
        case "--policy-repository": result.repository = value
        case "--agents-file":
            guard !value.hasPrefix("/"), !value.split(separator: "/").contains("..") else {
                throw PolicyError("--agents-file must stay within the consumer root")
            }
            result.agentsFile = value
        default: throw PolicyError("unknown argument: \(values[index])")
        }
        index += 2
    }
    if result.roots.isEmpty { result.roots = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath)] }
    return result
}

/// Synchronizes all requested roots against one verified source and reports every failed root.
func main() -> Int32 {
    do {
        let options = try parse(Array(CommandLine.arguments.dropFirst()))
        let snapshot = try loadSnapshot(options)
        var failures = 0
        for root in options.roots {
            do {
                let profile = try profile(for: root, options: options)
                let file = root.appendingPathComponent(options.agentsFile)
                let original = try String(contentsOf: file, encoding: .utf8)
                if options.mode == "update" {
                    let replacement = try updated(original, snapshot: snapshot, profile: profile)
                    if replacement != original { try replacement.write(to: file, atomically: true, encoding: .utf8) }
                }
                let final = try String(contentsOf: file, encoding: .utf8)
                try check(final, snapshot: snapshot, profile: profile)
                print(
                    "Validated \(root.lastPathComponent): \(profile), review policy \(snapshot.revision), source \(snapshot.commit)."
                )
            } catch {
                failures += 1
                FileHandle.standardError.write(Data("\(root.lastPathComponent): \(error)\n".utf8))
            }
        }
        return failures == 0 ? 0 : 1
    } catch {
        FileHandle.standardError.write(Data("Review policy verification failed: \(error)\n".utf8))
        return 1
    }
}

exit(main())
