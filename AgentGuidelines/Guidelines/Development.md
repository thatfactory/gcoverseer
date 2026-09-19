# Development

## Reusability first

When developing a new feature or responding to a feature request, consider shared code first. If the code fits an existing package, suggest extending that package instead of adding the implementation directly to an application. Also consider whether the change belongs in a new Swift package, even when that package does not exist yet. Prefer reusable, focused package APIs when they can serve more than one consumer.

## External dependencies

ThatFactory applications, games, and reusable packages are first-party by default. Do not introduce a new third-party source or binary dependency during normal feature development. Prefer Apple platform APIs, the Swift standard library, code owned by the current repository, or a focused ThatFactory-owned package. If reusable capability is missing, implement it natively at the appropriate boundary and consider extracting it into a first-party package when it can serve multiple consumers.

Do not add a third-party dependency merely to save implementation time, reduce code volume, or avoid learning a platform API. Do not make an external dependency acceptable by hiding it behind a first-party wrapper.

An exception requires explicit approval from the repository owner for the specific dependency and use before changing the dependency graph. If approved, record the decision in durable repository documentation in the same change, such as the architecture document or an ADR. Record the dependency and source, purpose and target scope, why a native or first-party implementation is not appropriate, relevant license, security, and maintenance considerations, version or update policy when material, and the approval context. Do not infer approval from an execution plan, pull-request description, agent choice, or transient chat that merely mentions or uses the dependency. Regardless of where explicit approval occurs, reflect the exception in durable repository documentation.

An existing approved dependency does not authorize a different dependency. Expanding an existing third-party dependency to a new target or runtime role requires the same approval and documentation. Routine version updates that do not change the approved role remain governed by the intentional consumer-update workflow in [Packages](Packages.md).

For this policy, a third-party dependency is externally maintained source or binary code linked into or shipped with the product, including externally maintained Swift packages, vendored libraries, frameworks or XCFrameworks, CocoaPods, Carthage dependencies, and equivalent runtime libraries. Apple system frameworks and the Swift standard library are platform dependencies, not third-party dependencies. Packages maintained by ThatFactory are first-party dependencies.

Tooling dependencies explicitly required by these shared guidelines, such as documentation or build plugins used only by tooling, are pre-approved for that documented role. They must not be linked into or shipped with product runtime targets unless the repository owner separately approves and documents that use.

CocoaPods and Carthage are forbidden in every ThatFactory project and are not eligible for the exception process above. Use Swift Package Manager for package dependencies.

## Guidelines version

Before changing a project, verify that it uses the latest released version of `agent-guidelines`. Check the project's `AgentGuidelines/VERSION` against the latest release, update the subtree or equivalent when it is behind, and read the updated applicable guides before starting implementation. This check is manual and must be performed at the beginning of each project task.

## Guidelines changes in pull requests

Keep `AgentGuidelines/` tracked so consumers retain a reproducible, versioned copy for agents and CI. Do not add the subtree to `.gitignore`. Instead, add this rule to the consumer's tracked `.gitattributes` so GitHub collapses synchronized guideline files in pull-request diffs by default while reviewers can still expand them:

```gitattributes
# Synced from thatfactory/agent-guidelines; keep tracked but collapse GitHub diffs.
AgentGuidelines/** linguist-generated
```

Keep each subtree update in its own commit. In the pull-request description, state the old and new guideline versions and link to the central release or pull request where the guideline changes were reviewed. Continue validating the checked-in subtree in CI. Because generated-file diffs are collapsed by default, never edit the subtree locally; make shared changes in the source repository and consume a tagged release.

## Completion audit

Before claiming implementation is complete, handing work to the user, preparing, opening, or updating a pull request, declaring merge readiness, or preparing a release, invoke `$agent-guidelines-audit`.

If the skill is not discoverable in a subtree consumer, read and follow its [SKILL.md](../.agents/skills/agent-guidelines-audit/SKILL.md) directly. The audit is a final verification gate, not a substitute for reading and applying the relevant guidelines during implementation. Resolve in-scope findings and rerun affected checks before handoff. Do not broaden the requested scope merely to satisfy the audit.

For subtree consumers, the audit runs `AgentGuidelines/Scripts/validate_consumer_setup.swift` to detect drift in the root Code Review and Documentation Maintenance contracts, Codex subtree-review scope, `.gitattributes`, local guide links, and repository skill symlink. When the root `AGENTS.md` links the shared Swift-format guide, the validator also requires the shared configuration symlinks and strict non-mutating CI adoption. User-level global Codex instructions are outside this repository audit.

## Post-merge cleanup

After an in-scope feature pull request merges, switch the original checkout back to the repository's primary branch, update it from its upstream with a fast-forward-only pull, and delete the merged local feature branch. Confirm the remote feature branch is absent when the repository deletes merged branches automatically. Do this before declaring the feature workflow complete so stale branches do not accumulate.

Never discard unrelated changes to perform cleanup. If the original checkout is dirty, another worktree still uses the feature branch, the merge did not complete, or the primary branch cannot fast-forward, leave the branch intact and report the exact blocker. Do not use force deletion merely to hide an unmerged branch.

## Logging

Applications own their orchestration, lifecycle, and product-domain diagnostics. Follow the shared [logging guide](Logging.md) and rely on each dependency to log its own implementation. Do not duplicate or reformat package-internal operations in the application log.

Treat observability as part of implementing or changing stateful, asynchronous, fallible, or lifecycle-oriented behavior. Before handoff, trace those boundaries and verify that privacy-safe AppLogger events distinguish the outcomes needed to diagnose the behavior in context. Merely adding the dependency or linking its product is not sufficient. Keep pure value and utility code silent when it has no meaningful event boundary, and record that deliberate decision in the handoff rather than manufacturing noisy logs.
