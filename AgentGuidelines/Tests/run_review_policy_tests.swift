#!/usr/bin/env swift
import Foundation

#if canImport(Darwin)
    import Darwin
#else
    import Glibc
#endif

let sourceRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let manager = FileManager.default

/// One executed process with complete combined diagnostics.
struct Result {
    let status: Int32
    let output: String
}

/// A focused regression-test failure.
struct Failure: Error, CustomStringConvertible {
    let description: String
}

/// Executes an argument vector without interpreting repository text as shell syntax.
func run(_ arguments: [String], at root: URL? = nil) throws -> Result {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = arguments
    process.currentDirectoryURL = root
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let bytes = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return Result(status: process.terminationStatus, output: String(decoding: bytes, as: UTF8.self))
}

/// Asserts a condition with actionable diagnostics.
func require(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    if try !condition() { throw Failure(description: message) }
}

/// Writes fixture data while preserving its literal content.
func write(_ text: String, _ url: URL) throws {
    try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
}

/// Reads a UTF-8 fixture.
func read(_ url: URL) throws -> String {
    try String(contentsOf: url, encoding: .utf8)
}

/// Runs a Git fixture mutation and verifies success.
func git(_ arguments: [String], at root: URL) throws -> String {
    let result = try run(["git"] + arguments, at: root)
    try require(result.status == 0, result.output)
    return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Owns isolated, locally published policy tags and consumer repositories.
struct Fixture {
    let root: URL
    let repository: URL
    let canonical: String

    /// Creates a minimal source repository, including an annotated policy tag.
    init() throws {
        root = manager.temporaryDirectory.appendingPathComponent("policy-tests-\(UUID().uuidString)")
        repository = root.appendingPathComponent("policy")
        canonical = try read(sourceRoot.appendingPathComponent("ReviewPolicy/Policy.md"))
        try write(canonical, repository.appendingPathComponent("ReviewPolicy/Policy.md"))
        try write("1\n", repository.appendingPathComponent("ReviewPolicy/VERSION"))
        _ = try git(["init", "--quiet"], at: repository)
        _ = try git(["config", "user.name", "Policy test"], at: repository)
        _ = try git(["config", "user.email", "policy@example.com"], at: repository)
        _ = try git(["add", "."], at: repository)
        _ = try git(["commit", "--quiet", "-m", "Policy one"], at: repository)
        _ = try git(["tag", "-a", "codex-review-v1", "-m", "Immutable policy one"], at: repository)
    }

    /// Creates a consumer with identifiable local instructions and optional obsolete copies.
    func consumer(_ name: String, full: Bool = false, obsolete: Bool = false) throws -> URL {
        let consumer = root.appendingPathComponent(name)
        var value = "# Local project\n\nPreserve local BEFORE instructions.\n"
        if obsolete {
            let old = canonical.components(separatedBy: "\n\n<!-- BEGIN THATFACTORY PR LIFECYCLE")[0]
                .replacingOccurrences(of: "CONTRACT v3", with: "CONTRACT v1")
            value += "\n" + old + "\n\nPreserve local BETWEEN instructions.\n\n" + old + "\n"
        }
        value += "\nPreserve local AFTER instructions.\n"
        try write(value, consumer.appendingPathComponent("AGENTS.md"))
        if full {
            try manager.createDirectory(
                at: consumer.appendingPathComponent("AgentGuidelines"), withIntermediateDirectories: true)
        }
        return consumer
    }

    /// Executes the production synchronizer against local immutable source objects.
    func sync(_ mode: String, _ consumer: URL, profile: String = "review-only", extra: [String] = []) throws -> Result {
        try run(
            [
                sourceRoot.appendingPathComponent("Scripts/sync_codex_review_policy.swift").path,
                mode, "--consumer-root", consumer.path, "--profile", profile,
                "--policy-repository", repository.path,
            ] + extra)
    }

    /// Removes all temporary state after the test completes.
    func cleanup() { try? manager.removeItem(at: root) }
}

let tests: [(String, () throws -> Void)] = [
    (
        "both profiles preserve local instructions and synchronize idempotently",
        {
            let fixture = try Fixture()
            defer { fixture.cleanup() }
            for full in [false, true] {
                let root = try fixture.consumer(full ? "full" : "review-only", full: full, obsolete: true)
                let profile = full ? "full" : "review-only"
                let update = try fixture.sync("update", root, profile: profile)
                try require(update.status == 0, update.output)
                let first = try read(root.appendingPathComponent("AGENTS.md"))
                for token in ["BEFORE", "BETWEEN", "AFTER"] {
                    try require(first.contains("Preserve local \(token) instructions."), "lost local \(token)")
                }
                try require(
                    !first.contains("CONTRACT v1 -->\n## Code Review Rules"), "obsolete review contract survived")
                let second = try fixture.sync("update", root, profile: profile)
                try require(second.status == 0, second.output)
                try require(try read(root.appendingPathComponent("AGENTS.md")) == first, "update is not idempotent")
                let check = try fixture.sync("check", root, profile: profile)
                try require(check.status == 0, check.output)
            }
        }
    ),
    (
        "modified, duplicate, stale, and incorrect-source policies fail without writing",
        {
            let fixture = try Fixture()
            defer { fixture.cleanup() }
            let root = try fixture.consumer("consumer")
            let update = try fixture.sync("update", root)
            try require(update.status == 0, update.output)
            let file = root.appendingPathComponent("AGENTS.md")
            let good = try read(file)
            let mutations = [
                good.replacingOccurrences(of: "P0/P1", with: "P0"),
                good + "\n" + fixture.canonical,
                good.replacingOccurrences(of: "revision=1", with: "revision=0"),
                good.replacingOccurrences(of: "source=", with: "incorrect-source="),
                good + "\n<!-- BEGIN THATFACTORY CODE REVIEW CONTRACT malformed -->\n",
            ]
            for value in mutations {
                try write(value, file)
                let check = try fixture.sync("check", root)
                try require(check.status != 0, "invalid policy passed")
                try require(try read(file) == value, "check mutated instructions")
            }
            try write(mutations.last!, file)
            let invalidUpdate = try fixture.sync("update", root)
            try require(invalidUpdate.status != 0, "malformed update unexpectedly succeeded")
            try require(try read(file) == mutations.last!, "failed update changed instructions")
        }
    ),
    (
        "a new policy revision blocks old consumers while unrelated releases do not",
        {
            let fixture = try Fixture()
            defer { fixture.cleanup() }
            let root = try fixture.consumer("consumer")
            let first = try fixture.sync("update", root)
            try require(first.status == 0, first.output)
            try write("Unrelated guide change.\n", fixture.repository.appendingPathComponent("README.md"))
            _ = try git(["add", "."], at: fixture.repository)
            _ = try git(["commit", "--quiet", "-m", "Unrelated guide release"], at: fixture.repository)
            let unchanged = try fixture.sync("check", root)
            try require(unchanged.status == 0, unchanged.output)
            try write("2\n", fixture.repository.appendingPathComponent("ReviewPolicy/VERSION"))
            _ = try git(["add", "."], at: fixture.repository)
            _ = try git(["commit", "--quiet", "-m", "Policy two"], at: fixture.repository)
            _ = try git(["tag", "codex-review-v2"], at: fixture.repository)
            let stale = try fixture.sync("check", root)
            try require(stale.status != 0, "old revision accepted")
            let updated = try fixture.sync("update", root)
            try require(updated.status == 0, updated.output)
            let checked = try fixture.sync("check", root)
            try require(checked.status == 0, checked.output)
        }
    ),
    (
        "unavailable sources, tag/version disagreement, and profile bypass fail closed",
        {
            let fixture = try Fixture()
            defer { fixture.cleanup() }
            let root = try fixture.consumer("consumer")
            let unavailable = try fixture.sync(
                "check", root, extra: ["--policy-repository", fixture.root.appendingPathComponent("absent").path])
            try require(unavailable.status != 0, "unavailable source passed")
            let wrongProfile = try fixture.sync("update", root, profile: "full")
            try require(wrongProfile.status != 0, "wrong profile passed")
            let localBypass = try fixture.sync("update", root, extra: ["--local-source", sourceRoot.path])
            try require(localBypass.status != 0, "consumer bypassed immutable source verification")
            _ = try git(["tag", "codex-review-v2"], at: fixture.repository)
            let mismatch = try fixture.sync("update", root)
            try require(mismatch.status != 0 && mismatch.output.contains("disagree"), mismatch.output)
        }
    ),
    (
        "current review, stale signals, remediation closure, and timeout remain distinct",
        {
            let guide = try read(sourceRoot.appendingPathComponent("Guidelines/GitHub/PullRequests.md"))
            let source = try read(sourceRoot.appendingPathComponent("Scripts/validate_guidelines.swift"))
            let invariants = [
                "the exact request-comment reactions",
                "never relabel the newer head as bot-reviewed",
                "Completed initial review plus a locally verified remediation-only delta | `completed` | Satisfied",
                "At the deadline, stop and terminate the monitor, report the observed facts once, and never infer approval",
            ]
            for invariant in invariants {
                try require(
                    guide.contains(invariant) && source.contains(invariant),
                    "missing protected review scenario: \(invariant)")
            }
            try require(
                try fixturelessPolicy().contains("New unrelated scope belongs in another PR"), "scope boundary missing")
        }
    ),
]

/// Reads canonical policy for assertions without constructing a remote fixture.
func fixturelessPolicy() throws -> String {
    try read(sourceRoot.appendingPathComponent("ReviewPolicy/Policy.md"))
}

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
if failures > 0 { exit(1) }
print("All \(tests.count) review-policy test groups passed.")
