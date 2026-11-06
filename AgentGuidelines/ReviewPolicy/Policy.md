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
