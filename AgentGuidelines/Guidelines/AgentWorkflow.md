# Agent Workflow

Use this guide for repository investigation and tool execution. It governs how work is explored and coordinated; language, architecture, testing, and development requirements remain in their respective guides.

This guidance is motivated by high token consumption from unnecessary model and tool cycles during read-heavy investigation, as described in [openai/codex#35050](https://github.com/openai/codex/issues/35050). It aims to avoid unnecessary cycles while preserving coverage and correctness; it does not guarantee a particular reduction in token usage.

## Bounded investigation

Investigate in bounded stages based on the current task.

Within a stage, group independent, already-known read-only operations when the available tools support doing so efficiently. Examples include targeted searches, reads of already-identified files, independent metadata checks, and inspection of separate tests or call sites.

Use an appropriate supported mechanism for grouped or concurrent execution. A current implementation might use batched tool calls, concurrent shell operations, `Promise.allSettled`, or an equivalent approach, but no particular API is required.

Inspect every result relevant to the conclusion. Account for failed, incomplete, and contradictory results rather than treating execution as successful merely because it was grouped.

## Dependency and ordering

Keep operations sequential when a result determines the next step or when ordering is observable.

This includes:

- adaptive investigation;
- approval-sensitive operations;
- related or conflicting mutations;
- edits followed by compilation or validation;
- diagnostics whose result determines the next change;
- stateful external operations;
- waits and resumptions.

Architecture-specific ordering requirements remain authoritative. For example, follow the Redux guide for dispatch and side-effect ordering rather than inferring that investigation-level concurrency permits runtime concurrency.

Do not group operations merely because concurrency is available.

## Scope and output

Keep each stage narrowly scoped to the request.

Prefer targeted searches, relevant line ranges, focused diagnostics, and specific log sections over broad repository, file, or log dumps.

Bound the combined output of grouped operations so that every result can be inspected reliably. When evidence is incomplete or truncated, retrieve only the missing portion rather than repeating the full investigation.

Do not expand the investigation merely because additional operations can be executed concurrently.

## Bounded iteration

Before starting an iterative review, remediation, or model-assisted refinement loop, define its objective, blocking threshold, round budget, and stop condition. New non-blocking observations do not reset the budget or widen the original objective.

Do not translate feedback directly into both a change and another review request. Classify the feedback, group items with the same root cause, batch accepted corrections, and rerun only the validation or bounded review needed to verify them.

Stop when the stated acceptance condition is satisfied. Zero possible comments, improvements, or edge cases is not a valid completion criterion. For pull-request review severity, state tracking, and round limits, follow [GitHub pull requests](GitHub/PullRequests.md).

## Efficiency

Avoid unnecessary repeated model and tool cycles when several independent operations are already known.

Efficiency must not reduce required coverage, bypass validation, conceal failures, or introduce unrelated work.
