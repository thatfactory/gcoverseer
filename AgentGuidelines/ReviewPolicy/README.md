# Codex Review Policy

The [canonical policy](Policy.md) contains the only authored reviewer and PR-lifecycle contracts. [VERSION](VERSION) is its independent positive integer revision. Full consumers adopt engineering guides through `AgentGuidelines/`; review-only consumers install the two managed sections directly in root `AGENTS.md` and a small CI integration. The central root, global review instructions, and full consumer template mirror this canonical text and are validated together. A Markdown link is navigation, not an instruction include.

## Profiles and synchronization

Start a review-only repository with a root `AGENTS.md` describing its actual purpose and local constraints. Do not install unrelated Apple development guidance. Run the central synchronizer against the consumer:

```sh
Scripts/sync_codex_review_policy.swift update --consumer-root <repository> --profile review-only
Scripts/sync_codex_review_policy.swift check --consumer-root <repository> --profile review-only
```

Use `--profile full` for a repository with an `AgentGuidelines/` subtree. Repeated `--consumer-root` options synchronize several repositories against one source resolution. The synchronizer updates only the provenance comment and complete managed contracts; it preserves local instructions, removes obsolete/duplicate complete contracts, and refuses malformed marker pairs. `check` never writes files. Review-only consumers need no vendored directory, formatter setup, or completion-audit symlink.

The provenance comment records profile, policy revision, and the exact published source commit. Latest-policy verification always uses `thatfactory/agent-guidelines`. `--policy-repository` exists for isolated test fixtures; production CI never accepts a consumer-controlled repository override. Source documents are data and are never executed. `--local-source` is restricted to central/template development, whose source is `local` because a commit cannot contain its own hash; it cannot satisfy a consumer's published-provenance check.

## CI and freshness

Run the shared `.github/actions/codex-review-policy` composite action from an immutable full commit SHA, with `profile: full` or `profile: review-only`. Reuse an existing Swift-capable job after checkout, or add a small hosted `macos-latest` job when the repository has none. Make the hosting job a required check. The action invokes the pinned Swift validator; it downloads only canonical policy text and never runs executable code from a newly discovered tag. Do not run consumer scripts to validate policy text.

The validator resolves the highest published `codex-review-vN` tag once per invocation, verifies the fetched tag object, peels its commit, checks that `ReviewPolicy/VERSION` agrees, and compares the exact managed contracts and provenance. Missing/modified/obsolete/duplicated sections, incorrect profile/source, older policy revisions, unavailable sources, and uncertain tag identity fail closed. An unrelated guideline release leaves the review-policy tag unchanged and does not force review-only updates.

A green CI run cannot invalidate itself when a later policy tag appears. The executor must rerun the latest-policy check immediately before merge. Publishing a policy revision includes a coordinated consumer rollout; CI never edits files, opens PRs, or merges updates itself. Keep consumer inventories and private repository names in the authorized local task, not in this public repository.

## Publishing and bootstrapping

Change the canonical contracts, increment the independent policy revision, synchronize mirrors, and validate through the central PR. Prepare the regular guidelines release metadata as usual. After the reviewed release commit is merged and validated, publish its normal guidelines tag/release, then create the immutable `codex-review-vN` tag at that same commit. Never move a published policy tag. Only policy changes need a new policy tag; all other guidelines releases retain the existing policy revision.

The central PR and release validation use owned local policy data, allowing a new revision to be tested before publication. The first consumer rollout starts only after the policy tag is public. Central development commands are:

```sh
Scripts/sync_codex_review_policy.swift update --local-source . --profile central
Scripts/sync_codex_review_policy.swift update --local-source . --profile template --agents-file Templates/AGENTS.md
Scripts/sync_codex_review_policy.swift check --local-source . --profile central
```

Synchronize the global template's review-only section from the same canonical reviewer block. Copy the global template into user-level Codex instructions; copy only its reviewer section into Settings → Code Review → Review Instructions for reviews started with Review with Codex. These settings are a matching user-level layer, not the source of automatic GitHub review policy. Configure all PR authors, opening/ready triggers, exhaustive review off, and separate automatic Security Review off. Record repository-specific configuration outside managed contracts.
