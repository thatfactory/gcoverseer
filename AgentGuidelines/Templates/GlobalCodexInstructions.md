# Global Codex Instructions

For repositories containing an `AGENTS.md`, read and follow the applicable repository instructions before starting substantive work.

When a repository includes shared agent guidelines, read the relevant guides referenced by the applicable `AGENTS.md` on demand. Treat those guides as the source of truth for language conventions, architecture, development workflow, testing, and agent execution.

Repository and folder-level instructions may specialize the shared baseline within their scope. Do not replace deliberate repository conventions with generic global preferences.

Do not duplicate repository-specific guidance in global instructions. Global instructions should bootstrap discovery of the repository's own sources of truth.

<!-- BEGIN THATFACTORY CODE REVIEW CONTRACT v3 -->
## Code Review Rules

Report only substantiated P0/P1 defects introduced or materially exposed by this change. Require a concrete, reachable failure in a supported use case or documented threat model, with serious impact such as a security-boundary bypass, durable data loss or corruption, a crash or deadlock in an important workflow, loss of availability, or a serious compatibility regression. An acceptance-criterion violation alone does not establish P1 severity.

For each finding, state severity, preconditions, execution path, impact, evidence, and actionable remediation. Group manifestations of one root cause. Report substantiated blockers together. Omit unsolicited P2/P3 observations, style preferences, speculative hardening, optional tests, and refactors. A clean review means no unresolved P0/P1 blockers, not perfect software.

A follow-up review covers unresolved P0/P1 findings, changes since the previous reviewed commit, and directly affected code. Do not restart a full review of unchanged code. New follow-up findings must be P0/P1 defects introduced by remediation or genuinely hidden by the previous blocker.
<!-- END THATFACTORY CODE REVIEW CONTRACT v3 -->
