# Agent Guidelines

## Purpose

This public repository is the versioned source of truth for reusable ThatFactory agent guidance. Keep it generic enough to apply to multiple applications and Swift packages. Product decisions, concrete project paths, and exceptions belong in each consumer repository.

## Sources of truth

- Use official Apple documentation for Apple APIs and Xcode behavior.
- Distill durable policy from Xcode-provided skills; do not copy exported Apple skills into this repository.
- Do not include private company information, credentials, personal absolute paths, or consumer-specific implementation details.
- When shared and consumer guidance differ, the consumer's nearest applicable `AGENTS.md` is the explicit specialization.
- Before changing this repository, verify that the consumer's checked-in guidelines version is current where applicable.

## Documentation changes

- Keep each rule in the narrowest relevant guide and link to it rather than duplicating it.
- Use physical folder terminology for Xcode projects. Do not call filesystem folders Xcode groups.
- Keep examples generic and concise.
- Use relative Markdown links inside this repository.
- Update `README.md` when adding, moving, or removing a guide.
- Keep the README guideline catalog sorted alphabetically by link label.
- Update `CHANGELOG.md` and `VERSION` for a release.
- When releasing a new version, update the version in both the README installation command and the README consumer-update command. Keep both commands aligned with the new release, for example:

  ```sh
  git subtree add \
    --prefix=AgentGuidelines \
    https://github.com/thatfactory/agent-guidelines.git \
    <version> \
    --squash

  git subtree pull \
    --prefix=AgentGuidelines \
    https://github.com/thatfactory/agent-guidelines.git \
    <version> \
    --squash
  ```

## Repository scripts

- Write new repository-owned executable scripts in Swift using the standard library and Foundation.
- `Scripts/swift_format.sh` is the sole retained shell-script exception because it is the existing command wrapper around Xcode's `swift-format`; do not use it as precedent for new shell automation.
- Do not add Python, Ruby, JavaScript, or other scripting-language runtimes for repository automation.

<!-- THATFACTORY CODEX REVIEW POLICY profile=central revision=1 source=local -->
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

## Validation

Run:

```sh
Scripts/validate_guidelines.swift
Tests/run_tests.swift
Scripts/sync_codex_review_policy.swift check --local-source . --profile central
```

Fix every validation failure before releasing a version.

## Consumer pull-request review scope

When reviewing a consumer pull request, do not review or comment on files under `AgentGuidelines/**` after exact tagged-tree provenance has been verified. That subtree is a tracked, synchronized copy marked `linguist-generated`; substantive guideline changes are reviewed in this repository. Verify the intended `AgentGuidelines/VERSION`, compare the subtree tree with the matching central tag (for example by comparing `git rev-parse HEAD:AgentGuidelines` with the fetched tag's root tree), and verify the required `.gitattributes` rule. If provenance does not match exactly, review the subtree contents and stop the merge. Report substantive guideline feedback against the central `agent-guidelines` pull request instead.

## Releases

- Use semantic versioning.
- Create a Git tag and GitHub release matching `VERSION`.
- Consumer repositories adopt releases deliberately through Git subtree updates.
- Follow [the pull-request review workflow](Guidelines/GitHub/PullRequests.md) before merging any release change.

## Repository review configuration

Automatic Codex PR review is enabled. Use all PR authors and the opening/ready trigger, keep exhaustive review off, and keep separate Security Review manual. Apply the managed lifecycle and [review-policy integration](ReviewPolicy/README.md).
