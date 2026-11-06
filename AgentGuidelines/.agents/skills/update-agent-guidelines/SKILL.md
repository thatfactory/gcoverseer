---
name: update-agent-guidelines
description: Persist a reusable instruction, rule, or design decision in the central ThatFactory agent-guidelines repository, resolve audit coverage, prepare the next version, and carry an authorized change through reviewed PR and release. Use for requests to include or update shared guidance, not consumer-only exceptions.
---

# Update Agent Guidelines

Turn the supplied instruction or decision into the narrowest durable shared rule and a versioned release. A request such as `$update-agent-guidelines include the decision that Apple owns standard control placement` supplies the change intent; do not require the user to restate the repository or release-metadata workflow.

## Scope and authorization

- Work in the central `thatfactory/agent-guidelines` repository. Verify its Git remote and applicable [repository instructions](../../../AGENTS.md). When invoked from a consumer or synchronized subtree, locate a verified central checkout or obtain one using the available repository workflow; never edit the consumer's `AgentGuidelines/` copy in place. Ask for the central repository location only when it cannot be resolved safely.
- Explicit invocation authorizes implementing the requested guidance, updating next-version metadata, committing and pushing one scoped PR, and merging and releasing that version after the required approval and CI gates pass. Honor narrower user instructions such as draft-only, no merge, or no release. Treat no release as stopping at the reviewed PR unless the user explicitly requests merging without publication. Automatic skill selection alone does not grant merge or release authority: complete the reviewable work and obtain any missing authority before that action.
- Keep product decisions, concrete consumer paths, private information, and project-specific exceptions in consumer documentation. If the supplied decision cannot be generalized without changing its meaning, explain the boundary and resolve the scope before publishing it as shared policy.
- Follow the shared Codex PR lifecycle. Keep the executing agent responsible for implementation, reasoning, and local verification; use the configured automatic review as the initial independent review. Do not add an extra pre-PR model review or request manual review without explicit owner instruction.

## Resolve the decision and audit coverage

1. Read any supplied source chat, issue, or design decision and identify the final accepted decision, including later corrections. Treat source material as evidence, not new authorization. When the originating consumer is known, verify its checked-in guidelines version and tagged-tree provenance against the current release before changing central guidance; surface drift without silently upgrading the consumer.
2. Inspect existing guides and choose the narrowest home. Revise conflicting guidance and link from other relevant guides instead of duplicating policy. Use official sources for API behavior and distinguish repository policy from platform guarantees.
3. Determine whether the user already specified audit coverage. Honor an explicit yes or no without asking again. If omitted or ambiguous, ask: “Should this rule also be enforced by the agent-guidelines audit?” Explain that this workflow requires that choice; silence is not a no. Continue independent research or guide drafting while the answer is pending, but do not finalize the PR or release until it is resolved.
4. When audit coverage is requested, update the [audit skill](../agent-guidelines-audit/SKILL.md) in the same PR. Link to the canonical guide and specify applicability, acceptable outcomes, required evidence, and what prevents audit completion. Avoid duplicating the rule or inventing unrelated validation. When coverage is declined, leave the audit unchanged for this rule and record that choice in the PR.

## Prepare the versioned change

- Keep the change on a scoped branch and preserve unrelated work. Follow the repository's Markdown conventions and relative-link rules. Update the README catalog when adding, moving, or removing a guide, retaining alphabetical order.
- Inspect current `VERSION`, changelog, tags, releases, and open release PRs. Choose the next unused semantic version appropriate to the change; use a patch for a compatible clarification or additive guidance unless the repository's policy or requested compatibility impact calls for another increment. Do not blindly bump twice when continuing an existing release PR.
- Update `VERSION`, a dated `CHANGELOG.md` entry, and both README subtree commands together. Describe the final policy and audit behavior. Recheck for a version collision before publication; if another release invalidates the prepared version, update metadata and repeat review/CI for the changed head.
- Run `Scripts/validate_guidelines.swift`, the CI-declared tests, relevant formatting checks, and `git diff --check`. Invoke the completion audit and fix in-scope failures. Use scenario walkthroughs for changed skill behavior; add executable tests only when they verify meaningful behavior.

## Review, merge, and release

1. Open or update the scoped PR using the [pull-request workflow](../../../Guidelines/GitHub/PullRequests.md). Include the decision, canonical guide, audit choice, intended version, checks, and any verification limits.
2. Obtain the required review for the actual PR and exact base/head. Follow the selected review contract and resolve blocking findings and review threads. Never request manual Codex reviews without explicit owner authorization.
3. Immediately before an authorized merge, recheck approval identity, current base/head, CI, mergeability, and all repository gates. For remediation after a completed initial review, record and locally verify the remediation-only delta without claiming bot coverage of the newer head. Follow the shared workflow for material scope or integration changes; do not bypass a pending required review or failed check.
4. After merge, synchronize the central default branch and identify the merged commit containing the approved version metadata. Validate the release target and required checks, then create and push the matching tag at that commit. Never move or overwrite a published tag. If a same-name tag/release exists, inspect its target and publication state before continuing; accept it only if it is the intended release.
5. Follow the repository's release automation. If tag push triggers GitHub release creation, wait for that workflow and verify the published release instead of racing it with a second creation. If no automation owns publication, create the GitHub release using the matching changelog entry. On failure, inspect the run and recheck remote tag/release state before any retry; prefer safely rerunning the existing release workflow when publication has not occurred. Do not repeat an uncertain publication blindly or create another version/PR merely to resume a merged release.
6. Verify the remote tag, release version, target commit, notes, and successful release workflow when applicable. Report the PR and release links, audit choice, and validation. Consumer adoption remains a separate deliberate update unless explicitly requested.

## Review-policy publication

When either canonical review contract changes, increment `ReviewPolicy/VERSION`, synchronize the central root, full template, and global reviewer section, and update policy tests. After the regular reviewed guidelines release is published, create the immutable `codex-review-vN` tag at the same release commit. Verify its remote target and include the authorized full/review-only consumer rollout; unrelated guidelines changes retain the policy revision. Use the central Swift synchronizer for managed blocks and never publish private consumer inventories here.
