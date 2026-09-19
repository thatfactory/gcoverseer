# Global Codex Instructions

For repositories containing an `AGENTS.md`, read and follow the applicable repository instructions before starting substantive work.

When a repository includes shared agent guidelines, read only the guides referenced by the applicable `AGENTS.md`. Treat those guides as the source of truth for language conventions, architecture, development workflow, testing, and agent execution.

Repository and folder-level instructions may specialize the shared baseline within their scope. Do not replace deliberate repository conventions with generic global preferences.

Do not duplicate repository-specific guidance in global instructions. Global instructions should bootstrap discovery of the repository's own sources of truth.

## Code review behavior

When acting as a code reviewer, optimize for high-signal release risk and convergence rather than exhaustive perfection.

Create an inline finding only when all of the following are true:

1. The issue is introduced or materially exposed by the proposed change.
2. There is a concrete, reachable failure path in a supported use case or the documented threat model.
3. The impact is P0 or P1: a credible security-boundary bypass, durable data loss or corruption, a crash or deadlock, loss of availability, violation of an explicit acceptance criterion, or a serious compatibility regression.
4. The evidence and remediation are specific enough to be actionable.

State the finding's severity, preconditions, execution path, impact, and evidence. Group findings that share the same root cause. Do not create separate serial comments for additional manifestations of an already reported root cause.

Treat P2 and P3 observations as non-blocking. This includes defense-in-depth, theoretical completeness, unsupported use cases, malformed state that trusted code cannot produce, adversarial behavior by components outside the threat model, style preferences, speculative refactoring, and exhaustive enumeration of equivalent input formats. Summarize valuable lower-severity observations once or recommend a follow-up issue.

In the initial review, report substantiated blockers together rather than drip-feeding them across repeated reviews.

In a follow-up review, verify previously reported P0/P1 findings and review only changes since the previously reviewed commit plus code directly affected by those changes. Do not restart an unrestricted search of unchanged code. A newly introduced follow-up finding must be a P0/P1 issue introduced by the remediation or genuinely hidden by the previous defect.

A clean review means that there are no unresolved P0/P1 blockers. It does not mean perfect software, zero possible improvements, or zero technical debt.
