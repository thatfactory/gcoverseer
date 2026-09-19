# GCOverseer

## Context

GCOverseer is a reusable Swift package. Read [README.md](README.md) before changing public behavior, supported platforms, or package integration.

## Shared guidelines

Read only the guides relevant to the task:

- [Agent workflow](AgentGuidelines/Guidelines/AgentWorkflow.md)
- [Swift](AgentGuidelines/Guidelines/Swift/Swift.md)
- [Swift style](AgentGuidelines/Guidelines/Swift/SwiftStyle.md)
- [SwiftUI](AgentGuidelines/Guidelines/Swift/SwiftUI.md)
- [Swift format](AgentGuidelines/Guidelines/Swift/SwiftFormat.md)
- [Localization](AgentGuidelines/Guidelines/Localization.md)
- [Unit and integration testing](AgentGuidelines/Guidelines/Testing/UnitTesting.md)
- [Documentation](AgentGuidelines/Guidelines/Documentation.md)
- [Logging](AgentGuidelines/Guidelines/Logging.md)
- [Packages](AgentGuidelines/Guidelines/Packages.md)
- [Development workflow](AgentGuidelines/Guidelines/Development.md)
- [CI/CD](AgentGuidelines/Guidelines/CICD.md)
- [Git repositories and SSH-first cloning](AgentGuidelines/Guidelines/Git/Repositories.md)
- [GitHub pull requests](AgentGuidelines/Guidelines/GitHub/PullRequests.md)
- [Xcode MCP and visual verification](AgentGuidelines/Guidelines/Xcode/MCP.md)
- [Xcode project settings](AgentGuidelines/Guidelines/Xcode/ProjectSettings.md)
- [Xcode security audits](AgentGuidelines/Guidelines/Xcode/Security.md)

For an application that uses Redux, also read [Redux architecture](AgentGuidelines/Guidelines/Architecture/Redux.md).

Keep the following observability contract in the consumer repository's root `AGENTS.md` so implementation agents treat runtime diagnostics as part of lifecycle work. Copy it unchanged and update it when the marker version changes in this template.

```md
<!-- BEGIN THATFACTORY RUNTIME OBSERVABILITY CONTRACT v1 -->
## Runtime Observability

Treat privacy-safe runtime observability as part of implementing or changing stateful, asynchronous, fallible, or lifecycle-oriented behavior. Identify the meaningful success, failure, cancellation, recovery, and state-transition boundaries before handoff, and emit concise AppLogger events owned by the artifact that implements them. Dependency declaration or target linkage alone does not satisfy this requirement.

Every ThatFactory package log starts with its canonical emoji and uses its own stable subsystem. Never log credentials, account or record identifiers, share URLs, captured content, images, or other user-generated values as public metadata. Keep pure values and utilities silent when they have no meaningful diagnostic event; record that deliberate decision in the implementation handoff instead of adding initializer or property-access noise. Follow [Logging](AgentGuidelines/Guidelines/Logging.md) for ownership, privacy, severity, message design, and tests.
<!-- END THATFACTORY RUNTIME OBSERVABILITY CONTRACT v1 -->
```

Keep the following marked external-dependency contract in the consumer repository's root `AGENTS.md` so implementation agents receive the rule directly before they make dependency choices. Copy it unchanged and update it when the marker version changes in this template.

```md
<!-- BEGIN THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1 -->
## External Dependency Policy

Do not introduce third-party source or binary dependencies into ThatFactory applications, games, or reusable packages during normal development. Prefer Apple platform APIs, the Swift standard library, code owned by the current repository, or focused ThatFactory-owned packages. If reusable capability is missing, implement it natively at the appropriate boundary and consider extracting it into a first-party package instead of selecting an external library.

A third-party dependency may be added, or expanded to a new target or runtime role, only with explicit repository-owner approval for that specific use before modifying the dependency graph. Convenience, reduced implementation effort, popularity, or an agent's preference for an existing library are not sufficient justification. Do not make an external library acceptable merely by hiding it behind a first-party wrapper.

Document every approved exception in durable repository documentation in the same change. Record the dependency and source, purpose and target scope, why a native or first-party implementation is not appropriate, relevant license, security, and maintenance considerations, and the approval context. Merely mentioning or using the dependency in an execution plan, pull-request description, or transient chat is not approval. Regardless of where explicit approval occurs, reflect the exception in durable repository documentation.

Apple system frameworks and the Swift standard library are not third-party dependencies. ThatFactory-owned packages are first-party dependencies. Tooling explicitly required by the shared guidelines is allowed only for its documented tooling role and must not be linked into or shipped with product runtime targets unless separately approved and documented.

Follow [Development workflow](AgentGuidelines/Guidelines/Development.md) for the detailed policy.
<!-- END THATFACTORY EXTERNAL DEPENDENCY CONTRACT v1 -->
```

Keep the following documentation-maintenance contract in the consumer repository's root `AGENTS.md` so implementation agents receive it directly rather than only through a linked guide. Copy it unchanged and update it when the marker version changes in this template.

```md
<!-- BEGIN THATFACTORY DOCUMENTATION MAINTENANCE CONTRACT v1 -->
## Documentation Maintenance

Treat documentation as part of implementation, not optional follow-up. At the start of implementation, identify code-level or project-level documentation likely to describe the affected behavior; before handoff, reconcile that documentation with the final implementation.

Update documentation when a change alters durable or core feature behavior or another documented contract. Regardless of change size, if the implementation makes existing documentation inaccurate, incomplete, misleading, or obsolete, update or remove that documentation in the same change.

Do not create documentation churn for incidental implementation details that are not durable and do not affect an existing documented claim. Follow [Documentation](AgentGuidelines/Guidelines/Documentation.md) for detailed scope and the completion checklist.
<!-- END THATFACTORY DOCUMENTATION MAINTENANCE CONTRACT v1 -->
```

Keep the following marked code-review contract in the consumer repository's root `AGENTS.md` so it is loaded directly for root-level Codex and pull-request work. Copy it unchanged and update it when the marker version changes in this template; a Markdown link to the detailed workflow is not an instruction include.

```md
<!-- BEGIN THATFACTORY CODE REVIEW CONTRACT v2 -->
## Code Review Rules

Review for release-blocking defects introduced or materially exposed by the pull request. A clean review means no unresolved P0/P1 findings; it does not mean exhaustive or perfect software.

A blocking finding must identify a concrete, reachable path in a supported use case or the documented threat model that can cause a credible security-boundary bypass, durable data loss or corruption, a crash or deadlock, loss of availability, violation of an explicit acceptance criterion, or a serious compatibility regression.

For every blocking finding, state the severity, preconditions, execution path, impact, evidence, and actionable remediation. Group manifestations that share the same root cause into one finding.

Treat P2/P3 observations as non-blocking, including defense-in-depth, theoretical completeness, unsupported use cases, malformed state that trusted code cannot produce, behavior by components outside the threat model, style preferences, and speculative refactoring. Record a useful lower-severity observation once as deferred, declined, duplicate, or follow-up work; do not keep the review loop open for it.

In an initial review, report substantiated blockers together. A follow-up review is limited to unresolved P0/P1 findings, changes since the last reviewed commit, and code directly affected by those changes. Do not restart an unrestricted review of unchanged code. A new follow-up finding must be a P0/P1 defect introduced by the remediation or genuinely hidden by the previous blocker.

The review-round budget below applies only to Codex GitHub reviews: the configured automatic Codex review and any manual `@codex review` request. It does not apply to ChatGPT review or reasoning delegated through Reasoning Relay. An otherwise-authorized Reasoning Relay workflow may request as many Relay review or follow-up delegations as its own governing workflow requires; those requests neither consume the Codex budget nor require repository-owner authorization under it.

Automatic Codex review is the initial Codex review. Do not request a manual Codex review unless the repository owner explicitly asks. Never request another Codex review after each remediation commit. Within the normal Codex review budget, at most one owner-authorized, delta-scoped Codex verification review may be requested under [the pull-request review workflow](AgentGuidelines/Guidelines/GitHub/PullRequests.md).
<!-- END THATFACTORY CODE REVIEW CONTRACT v2 -->

## Codex review scope

For consumer pull requests, do not substantively review `AgentGuidelines/**` after exact tagged-tree provenance has been verified. Verify its `VERSION`, compare its tree with the matching central tag, and verify the required `.gitattributes` rule. If provenance does not match exactly, review the subtree contents and stop the merge. Report substantive guideline feedback against the central `agent-guidelines` pull request.
```

The marked block is intentional controlled duplication of the shared review policy. The tracked, synchronized subtree is reviewed centrally in `thatfactory/agent-guidelines`; the root-level instructions ensure the review contract and subtree scope are loaded even when Codex starts from the repository root.

## Physical folder map

| Role | Physical folder |
|---|---|
| Package sources | `Sources/GCOverseer/` |
| Unit tests | `Tests/GCOverseerTests/` |

## Stack

- Swift 6.4 and Xcode 27.
- Platforms are declared in `Package.swift`.
- CI runner labels are `self-hosted` and `macOS`.
- Run `AgentGuidelines/Scripts/swift_format.sh format-and-lint Package.swift Sources Tests`, `swift test`, and `AgentGuidelines/Scripts/validate_consumer_setup.swift` before handoff.

## Local specialization

Keep the package focused on its existing public capability and preserve source compatibility unless a release explicitly documents a breaking change.
