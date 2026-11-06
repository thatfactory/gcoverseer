# Project Instructions

## Context

Describe the product or package, supported platforms, and durable constraints. Link to the project README or product documentation instead of duplicating it.

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
- [Networking](AgentGuidelines/Guidelines/Networking.md)
- [Packages](AgentGuidelines/Guidelines/Packages.md)
- [Development workflow](AgentGuidelines/Guidelines/Development.md)
- [CI/CD](AgentGuidelines/Guidelines/CICD.md)
- [Git repositories and SSH-first cloning](AgentGuidelines/Guidelines/Git/Repositories.md)
- [GitHub pull requests](AgentGuidelines/Guidelines/GitHub/PullRequests.md)
- [Xcode MCP and visual verification](AgentGuidelines/Guidelines/Xcode/MCP.md)
- [Device Hub, physical devices, and simulators](AgentGuidelines/Guidelines/Xcode/DeviceInteraction.md)
- [Xcode project settings](AgentGuidelines/Guidelines/Xcode/ProjectSettings.md)
- [Xcode security audits](AgentGuidelines/Guidelines/Xcode/Security.md)

For an application that uses Redux, also read [Redux architecture](AgentGuidelines/Guidelines/Architecture/Redux.md).

For Codex pull-request review, use the linked review evidence rules. If authoritative repository-specific evidence establishes that automatic review is enabled, apply its current-head gate. If the executing agent cannot establish the setting, record it as `unknown`; this template does not establish that automatic review is configured.

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
<!-- BEGIN THATFACTORY EXTERNAL DEPENDENCY CONTRACT v2 -->
## External Dependency Policy

Do not introduce third-party source or binary dependencies into ThatFactory applications, games, or reusable packages during normal development. Prefer Apple platform APIs, the Swift standard library, code owned by the current repository, or focused ThatFactory-owned packages. If reusable capability is missing, implement it natively at the appropriate boundary and consider extracting it into a first-party package instead of selecting an external library.

A third-party dependency may be added, or expanded to a new target or runtime role, only under an explicit standing approval in these guidelines or with explicit repository-owner approval for that specific use before modifying the dependency graph. Convenience, reduced implementation effort, popularity, or an agent's preference for an existing library are not sufficient justification. Do not make an external library acceptable merely by hiding it behind a first-party wrapper.

Document every approved exception in durable repository documentation in the same change. Record the dependency and source, purpose and target scope, why a native or first-party implementation is not appropriate, relevant license, security, and maintenance considerations, and the approval context. Merely mentioning or using the dependency in an execution plan, pull-request description, or transient chat is not approval. Regardless of where explicit approval occurs, reflect the exception in durable repository documentation.

Apple system frameworks and the Swift standard library are not third-party dependencies. ThatFactory-owned packages are first-party dependencies. Tooling explicitly required by the shared guidelines is allowed only for its documented tooling role and must not be linked into or shipped with product runtime targets unless separately approved and documented.

Follow [Networking](AgentGuidelines/Guidelines/Networking.md) for Apple-native networking and typed HTTP. Its narrow standing approval for Apple's `swift-http-types` applies only to the documented HTTPTypes and HTTPTypesFoundation runtime role; it does not approve other Apple open-source packages or unrelated roles. Use the guide's normal dependency documentation for that role instead of requesting a separate consumer exception.

Follow [Development workflow](AgentGuidelines/Guidelines/Development.md) for the detailed policy.
<!-- END THATFACTORY EXTERNAL DEPENDENCY CONTRACT v2 -->
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

Keep the following code-review and PR-lifecycle contracts directly in the consumer repository's root `AGENTS.md`. Synchronize them with `Scripts/sync_codex_review_policy.swift`; both full and review-only profiles use identical canonical text. The template provenance below is development-only: consumer synchronization replaces it with the profile, latest policy revision, and immutable published commit. A Markdown link is not an instruction include.

```md
<!-- THATFACTORY CODEX REVIEW POLICY profile=template revision=1 source=local -->
<!-- BEGIN THATFACTORY CODE REVIEW CONTRACT v3 -->
## Code Review Rules

Report only substantiated P0/P1 defects introduced or materially exposed by this change. Require a concrete, reachable failure in a supported use case or documented threat model, with serious impact such as a security-boundary bypass, durable data loss or corruption, a crash or deadlock in an important workflow, loss of availability, or a serious compatibility regression. An acceptance-criterion violation alone does not establish P1 severity.

For each finding, state severity, preconditions, execution path, impact, evidence, and actionable remediation. Group manifestations of one root cause. Report substantiated blockers together. Omit unsolicited P2/P3 observations, style preferences, speculative hardening, optional tests, and refactors. A clean review means no unresolved P0/P1 blockers, not perfect software.

A follow-up review covers unresolved P0/P1 findings, changes since the previous reviewed commit, and directly affected code. Do not restart a full review of unchanged code. New follow-up findings must be P0/P1 defects introduced by remediation or genuinely hidden by the previous blocker.
<!-- END THATFACTORY CODE REVIEW CONTRACT v3 -->

<!-- BEGIN THATFACTORY PR LIFECYCLE CONTRACT v1 -->
## Pull Request Lifecycle

Finish implementation, inspect the diff, and run relevant local validation before opening a ready-for-review PR. Drafts are for incomplete preparation; mark ready before waiting for automatic review. Keep the review head stable while the initial review runs. One automatic Codex review is the initial review; never duplicate it with a manual request or repeatedly toggle draft/ready state.

Establish review configuration from repository-specific evidence. Verify the bot, PR, review round, and reviewed commit using PR/request-comment reactions, review submissions, inline threads, and checks. Eyes means processing, not approval; a thumbs-up means no suggestions only for its verified review round. Historical reactions, missing comments, and elapsed time never certify a newer head. Monitor at most five minutes total with bounded, non-accelerating polls; timeout leaves a required gate unresolved and never authorizes merge.

Batch accepted P0/P1 fixes, verify them locally, rerun affected checks, and disposition and resolve every review thread. A completed initial review plus an explicitly recorded, locally verified remediation-only delta can satisfy the review gate; do not claim Codex reviewed the newer head. New unrelated scope belongs in another PR. Request at most one delta-scoped verification only when the owner explicitly authorizes it. Do not request reviews after every fix or casually mention the bot to start extra work. Separate Security Review is manual and requires explicit owner instruction.

Before merge, rerun the latest published review-policy check, confirm no required review is pending, no unresolved P0/P1 blocker remains, every thread is dispositioned and resolved, required checks pass on the current head, and existing human approval or merge authorization is satisfied. A bot thumbs-up is not a substitute for required GitHub approval. Opening a PR does not authorize merging it.
<!-- END THATFACTORY PR LIFECYCLE CONTRACT v1 -->

## Codex review scope

For consumer pull requests, do not substantively review `AgentGuidelines/**` after exact tagged-tree provenance has been verified. Verify its `VERSION`, compare its tree with the matching central tag, and verify the required `.gitattributes` rule. If provenance does not match exactly, review the subtree contents and stop the merge. Report substantive guideline feedback against the central `agent-guidelines` pull request.
```

The marked block is intentional controlled duplication of the shared review policy. The tracked, synchronized subtree is reviewed centrally in `thatfactory/agent-guidelines`; the root-level instructions ensure the review contract and subtree scope are loaded even when Codex starts from the repository root.

## Physical folder map

Replace these examples with exact repository paths:

| Role | Physical folder |
|---|---|
| Application sources | `<AppName>/` |
| Redux | `<AppName>/Redux/` |
| Views | `<AppName>/View/` |
| Services | `<AppName>/Services/` |
| Unit tests | `<AppName>Tests/` |

## Stack

Record the supported Xcode, Swift, and platform versions. Follow the shared Xcode project-settings baseline and record any exact, scoped exception in the local specialization or linked durable documentation.

## Local specialization

State only rules that specialize or override the shared baseline. Explain their scope and point to local source-of-truth documentation.
