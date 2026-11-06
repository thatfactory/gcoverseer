# GitHub Pull Requests

Use this guide whenever creating, reviewing, updating, or merging a GitHub pull request. The self-contained root contracts come from [the canonical review policy](../../ReviewPolicy/Policy.md); [review-policy integration](../../ReviewPolicy/README.md) describes both adoption profiles and freshness checks.

## Before opening

- Review the complete diff, keep one coherent review unit, and exclude unrelated changes. State supported use cases, acceptance criteria, threat-model boundaries, validation, and limitations in the PR description.
- Run relevant local validation and follow the repository's contribution instructions. Open a ready-for-review PR at a stable head without auto-merge. Drafts are appropriate for incomplete preparation, data approval, and source promotion; mark ready before waiting for automatic Codex review.
- Configure automatic review for all PR authors on opening a ready PR or marking ready, disable exhaustive review, and keep separate Security Review manual. Record actual repository configuration separately from the generic template; this template does not establish that automatic review is configured.
- One automatic full review is the initial review. Do not post a duplicate manual request, toggle draft/ready to force another round, or casually mention the bot. A mention can start extra cloud work. Manual review and Security Review require explicit owner instruction.

## Consumer subtree review scope

After exact tagged-tree provenance has been verified, do not substantively review `AgentGuidelines/**` in a consumer PR. Verify `AgentGuidelines/VERSION`, compare `git rev-parse HEAD:AgentGuidelines` with the matching central tag's root tree, and verify `.gitattributes` contains `AgentGuidelines/** linguist-generated`. A tree-object comparison avoids reconstructing subtree history. If provenance differs, review the discrepancy and stop merge. Substantive shared-policy feedback belongs in the central PR. Review-only consumers have no subtree to exclude.

## Review objective

Report only substantiated P0/P1 regressions introduced or materially exposed by the change. P0 is a critical security failure, catastrophic durable data loss, or critical outage. P1 requires serious, concrete impact in a supported workflow or documented threat boundary. An acceptance-criterion violation alone does not establish P1. Omit unsolicited P2/P3 hardening, style, optional tests, speculative refactoring, and theoretical completeness. Group one root cause into one finding and report blockers together.

## Review evidence and gate

Track configuration and execution separately in the active task, without adding runtime journals to the repository:

```text
codex_review_configuration = enabled | disabled | unknown
codex_review_configuration_evidence = <repository-specific source + observed_at> | unset
codex_review_execution = not_started | scheduled | processing | completed
codex_review_expected_sha = <head of the active review round>
codex_review_completed_sha = <actual reviewed commit> | unset
codex_initial_reviewed_base = <actual reviewed base> | unset
codex_remediation_verified_sha = <locally verified remediation-only head> | unset
```

Only positive repository-specific evidence establishes configuration: an observed setting, a durable local declaration, or explicit owner confirmation for this repository. Generic templates, another repository, old PR behavior, and an automation prompt are insufficient. With no signal, `unknown` plus no signal remains `not_started`. Discovering `enabled` alone does not schedule a review; the PR must meet its configured trigger. A declared required review with a conflicting disabled setting is a configuration problem to resolve, not a waived gate.

Verify bot identity, repository, PR, review round, and commit. Inspect PR-body reactions for automatic reviews and the exact request-comment reactions for authorized manual reviews, plus review submissions, inline threads, checks, and failure comments. Eyes is processing, not approval. A thumbs-up means no suggestions only when tied to the verified round and stable head; a historical reaction never certifies a newer head. A review with a commit ID must match the expected round SHA. Neither absent comments nor elapsed time establishes completion.

| Evidence | Execution | Merge gate | Start monitor |
| --- | --- | --- | --- |
| Enabled and positively eligible, no start signal | `scheduled` | Pending | Yes, at most five minutes |
| Enabled with a current-head processing signal | `processing` | Pending | Continue within original deadline |
| Enabled with a completed review covering the expected head and dispositioned findings | `completed` | Satisfied | No |
| Unknown with no signal or configuration evidence | `not_started` | Not blocked by absent Codex review | No |
| Disabled with no review | `not_started` | Not blocked by absent Codex review | No |
| Review completed for an old head | Re-establish for new head | Historical reaction alone is insufficient | No inherited monitor |
| Completed initial review plus a locally verified remediation-only delta | `completed` | Satisfied after all blockers and checks are cleared | No new review |

For the disabled outcome, the repository must not independently require Codex review. None of these outcomes grants merge authority or replaces required checks or human approval.

### Remediation and convergence

1. Record the initial reviewed base/head and inspect every review summary and inline thread. Classify each thread as `BLOCKER-P0`, `BLOCKER-P1`, `DEFER-P2`, `DEFER-P3`, `DECLINE`, or `DUPLICATE`.
2. Batch accepted P0/P1 fixes and add meaningful regression coverage where appropriate. Record useful unsolicited lower-priority feedback once; it does not keep the review loop open.
3. Reply in the original thread with its disposition and the change or technical rationale. Resolve only after recording the disposition. Write commit hashes as raw text, for example 185c04f, so GitHub links them.
4. Rerun affected validation, inspect the complete delta from the actual reviewed head, and record the final verified SHA and why the delta only remediates known findings. The completed initial review remains evidence for its original head; never relabel the newer head as bot-reviewed.
5. A completed initial review plus a locally verified remediation-only delta satisfies the agent-review step when no unresolved P0/P1 blocker remains. New unrelated functionality belongs in another PR. A material base/integration change requires renewed assessment and an owner-authorized targeted review when the original review no longer covers the risk.
6. Update PR metadata and immediately before merge rerun the latest review-policy check, inspect late findings and current-head checks, and verify existing merge authority. A thumbs-up is not a formal GitHub approving review.

Never request another review after each fix. The owner may explicitly authorize at most one delta-scoped verification after batching remediation. Before requesting it, confirm no review is pending, no request targets that head already, the head differs from the last reviewed SHA, and the verification budget is unused. Record the requested SHA and round before waiting. Scope the request to unresolved P0/P1 findings, changes since the actual reviewed SHA, and directly affected code. A new verification finding must be a P0/P1 defect introduced by remediation or genuinely hidden by the prior blocker. A third review requires separate explicit owner authorization and a named unresolved P0/P1 concern.

### Bounded monitoring

Monitor at most five minutes total from entry into `scheduled`, including time spent in `processing`. If processing is first observed without a known scheduling time, start the single bounded observation window then. Take an initial snapshot and at most one each around 30, 90, 180, and 300 seconds. A processing signal changes the execution state but does not reset the deadline or poll budget. A completion signal ends monitoring.

Keep the expected SHA, request identity, start, deadline, poll count, and a fingerprint covering base/head, signals, review commit, threads, checks, and mergeability. An identical fingerprint causes no substantive re-analysis or user notification. Without configuration evidence, do not create a monitor for an absent review. If the head changes during monitoring, terminate the old monitor; do not transfer `scheduled`, `processing`, or `completed` to a new round or infer that a push triggers another review.

At the deadline, stop and terminate the monitor, report the observed facts once, and never infer approval. An unresolved required round remains a merge blocker. Do not submit another request, create a recurring automation, or start fresh observation windows to evade the budget. Continue independent work or report the unresolved gate.

Use all relevant GitHub surfaces with complete pagination:

```sh
gh api --paginate repos/<owner>/<repo>/issues/<pr>/reactions
gh api --paginate repos/<owner>/<repo>/issues/comments/<request-comment>/reactions
gh pr view <pr> --repo <owner>/<repo> --json reviews,headRefOid,baseRefOid
gh pr checks <pr> --repo <owner>/<repo>
```

Use GraphQL `reviewThreads` with `isResolved` and paginated comment histories. Top-level PR comments omit inline thread state. Missing pages, unresolved threads, a processing reaction, and a timeout are never approval.

## Merge and late findings

Opening a PR does not authorize merging it. Squash merge only after current-head required checks, resolved/dispositioned threads, required review completion or verified remediation closure, and existing owner/human authorization are satisfied. Do not enable auto-merge while a gate remains pending. Prefer rulesets requiring PRs, conversation resolution, mandatory checks, and an intentional emergency bypass path. Require an up-to-date branch where repository policy calls for it.

GitHub does not count author self-approval. In a solo repository, do not impose an impossible one-approval gate; preserve explicit owner authorization and enforce the available technical gates. Review-policy validation is a required hosting check, not a substitute for code review.

Assess late findings individually. A valid late P0/P1 finding requires prompt corrective work and indicates a missed gate. A late P2/P3 observation can become backlog work and is not itself a process failure.
