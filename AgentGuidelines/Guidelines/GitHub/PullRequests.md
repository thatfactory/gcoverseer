# GitHub Pull Requests

Use this guide whenever creating, reviewing, updating, or merging a GitHub pull request.

## Before opening

- Review the complete diff and exclude unrelated changes.
- Keep each pull request to a coherent review unit with a bounded set of invariants. Split changes that combine independent architecture, persistence, security, transport, and CI concerns when they can be reviewed and delivered separately; do not split merely to minimize line count.
- State the supported use cases, explicit acceptance criteria, and relevant threat model for behavior whose review priority depends on those boundaries.
- For security guarantees based on enumerating formats or signatures, define the finite coverage contract and residual risk, or use a systemic boundary that enforces the guarantee without exhaustive enumeration.
- Follow the repository's pull-request template and local contribution instructions.
- Run the relevant local validation and document anything that could not be run.
- Open the pull request without auto-merge and keep it unmerged while automated or agent review is pending. Use draft state only when configured reviewers also run on drafts.
- When automatic Codex review is enabled, opening the pull request schedules the review. Do not also post `@codex review` or make another manual request; duplicate reviews waste review capacity and tokens. Do not request a Codex review manually unless the user explicitly asks for one.

## Consumer subtree review scope

When reviewing a consumer pull request, do not review or comment on files under `AgentGuidelines/**` after exact tagged-tree provenance has been verified. The subtree is a tracked, synchronized copy marked `linguist-generated`; substantive guideline changes are reviewed in the central `thatfactory/agent-guidelines` pull request. Verify `AgentGuidelines/VERSION`, compare the subtree tree with the matching central tag (for example with `git subtree split --prefix=AgentGuidelines HEAD` and a tree comparison after fetching that tag), and verify the required `.gitattributes` rule. If provenance does not match exactly, review the subtree contents and stop the merge. Report substantive guideline feedback against the central pull request instead.

## Review objective

Automated review identifies release-blocking regressions; it does not attempt to eliminate every possible improvement.

Classify findings by impact and reachable scope:

- **P0 — critical:** an actively exploitable critical security issue, catastrophic durable data loss, or critical production outage.
- **P1 — blocking:** a supported use case, explicit acceptance criterion, or documented threat-model boundary has a concrete reachable failure path that causes a security-boundary bypass, durable data loss or corruption, a crash or deadlock, loss of availability, or a serious compatibility regression.
- **P2 — non-blocking:** robustness, defense-in-depth, bounded edge cases, malformed state that trusted code cannot produce, unsupported scenarios, theoretical completeness, or useful hardening.
- **P3 — non-blocking:** style, naming, preferred refactoring, documentation polish, or optional test improvements.

Only unresolved P0 and P1 findings block merge. A finding may be technically correct without being release-blocking.

## Review gate

Opening a pull request starts review; it does not authorize merging it.

1. Wait for the configured Codex review to finish. No review yet means pending, not approved.
2. Record the reviewed head SHA and inspect all review summaries, inline threads, checks, and requested changes.
3. Assess each comment for technical correctness, severity, supported reachability, and root cause.
4. Give every thread one explicit disposition: `BLOCKER-P0`, `BLOCKER-P1`, `DEFER-P2`, `DEFER-P3`, `DECLINE`, or `DUPLICATE`.
5. Batch accepted P0/P1 corrections into one remediation pass and add regression coverage where reasonably possible. Lower-severity improvements may be included when they are small and clearly in scope, but they do not keep the review loop open.
6. Reply in the original thread with the disposition and either what changed or the concise technical reason for deferring, declining, or grouping it.
7. Resolve a thread only after its disposition is recorded. Reference a follow-up issue for deferred work when its value justifies one.
8. Rerun affected validation, then update the pull-request description so it matches the current implementation, validation, deferred work, and remaining limitations.
9. Recheck the pull request immediately before merge for late P0/P1 findings and check-state changes.

When replying with a commit reference, write the commit hash as raw text without backticks (for example, the hash 185c04f should remain 185c04f). GitHub then auto-links the hash to the commit.

A thumbs-up or clean Codex review satisfies the agent-review step, but it does not replace any human approval required by the repository. Do not enable auto-merge before all review gates are satisfied.

### Codex review state and round budget

This round budget applies only to Codex GitHub reviews: the configured automatic Codex review and any manual `@codex review` request. It does not apply to ChatGPT review or reasoning delegated through Reasoning Relay. An otherwise-authorized Reasoning Relay workflow may request as many Relay review or follow-up delegations as its own governing workflow requires; those requests neither consume this Codex budget nor require repository-owner authorization under it. Do not block an agentic goal waiting for a Codex-budget exception before issuing an otherwise-authorized Reasoning Relay request.

Track enough Codex-review state to prevent duplicate requests and unbounded Codex review loops:

```text
codex_initial_review_sha
codex_last_reviewed_sha
codex_review_requested_sha
codex_review_round
codex_pending_review
codex_unresolved_p0
codex_unresolved_p1
codex_deferred_findings
```

The automatic Codex review is the one initial full Codex review. Do not request another Codex review after each fix. A repository owner may explicitly authorize at most one delta-scoped Codex verification review after the known P0/P1 findings have been batch-remediated.

Before sending that Codex request, verify that no Codex review is pending, no existing request targets the current head SHA, the current head differs from `codex_last_reviewed_sha`, and the Codex verification-round budget is unused. Persist `codex_review_requested_sha`, increment `codex_review_round`, and mark `codex_pending_review` before waiting for a result so a retry cannot submit a duplicate request.

When authorized, scope the Codex verification request explicitly:

```text
@codex review only unresolved P0/P1 findings and changes since <last-reviewed-sha>.
Do not search unchanged code for new P2/P3 issues.
```

Do not request a third Codex review or restart a full Codex review without separate, explicit repository-owner authorization and a named unresolved P0/P1 concern. This restriction does not cap Reasoning Relay/ChatGPT review delegations. A new finding in Codex verification must be a P0/P1 defect introduced by the remediation or genuinely hidden by the previous blocker.

Stop the review loop when no unresolved P0/P1 finding remains, every thread has an explicit disposition, required checks pass, and required human authorization is present. Zero comments, zero possible improvements, and zero technical debt are not completion criteria.

### Codex review monitoring

Use GitHub review data, reactions, and checks together. An eyes reaction means Codex is processing the pull request; it is not an approval. A thumbs-up means the review completed without suggestions. A submitted review means its inline threads must be assessed individually.

```text
PR opened at stable head
   |
   v
One automatic full review
   |
   +--> thumbs-up ----------------> No P0/P1 blockers
   |
   `--> Review comments ----------> Classify and group
                                         |
                                 batch P0/P1 fixes
                                         |
                          owner-authorized delta review?
                              |                    |
                             no                   yes
                              |                    |
                            stop          one verification pass
                                                   |
                                        no unresolved P0/P1
                                                   |
                                                  stop
```

When using the GitHub CLI, monitor all three surfaces:

```sh
gh api --paginate repos/<owner>/<repository>/issues/<pull-request>/reactions
gh pr view <pull-request> --repo <owner>/<repository> --json reviews,headRefOid
gh pr checks <pull-request> --repo <owner>/<repository>
```

Retrieve inline review threads and their resolution state through GraphQL; top-level pull-request comments do not include this information:

```sh
gh api graphql --paginate \
  -f query='query($owner: String!, $repository: String!, $number: Int!, $endCursor: String) {
    repository(owner: $owner, name: $repository) {
      pullRequest(number: $number) {
        reviewThreads(first: 100, after: $endCursor) {
          nodes { id isResolved }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
  }' \
  -F owner=<owner> \
  -F repository=<repository> \
  -F number=<pull-request>
```

For every unresolved thread identifier returned above, retrieve its complete comment history with a second paginated query:

```sh
gh api graphql --paginate \
  -f query='query($thread: ID!, $endCursor: String) {
    node(id: $thread) {
      ... on PullRequestReviewThread {
        comments(first: 100, after: $endCursor) {
          nodes { id author { login } body url }
          pageInfo { hasNextPage endCursor }
        }
      }
    }
  }' \
  -F thread=<review-thread-id>
```

Continue polling only while an allowed review round is pending. Inspect every returned page for reactions, review threads, and thread comments. Do not treat missing comments, a pending reaction, truncated results, or elapsed time as review completion, and do not submit a duplicate request merely because polling has not completed.

## Merge method

ThatFactory repositories use squash merges by default. Do not attempt a merge commit; GitHub rejects that method in these repositories, and retrying with squash wastes execution time and tokens. Use the GitHub UI or `gh pr merge <pull-request> --squash` after all review, approval, and check requirements are satisfied. Use another merge method only when the repository explicitly allows it and the owner authorizes the exception.

## Merge requirements

Do not merge while any of the following is true:

- Codex review is still pending;
- an unresolved P0/P1 finding remains;
- a review thread lacks an explicit disposition or remains unresolved;
- a required check is pending or failing;
- the branch is out of date when the repository requires an up-to-date branch;
- required human approval or explicit owner authorization is missing.

## Late findings

If a review arrives after merge, assess and disposition its findings. A valid late P0/P1 finding requires prompt remediation through a corrective pull request and indicates that a review gate was missed. A late P2/P3 observation becomes backlog work when useful and is not by itself a process failure.

## Repository protection

Prefer GitHub rulesets or branch protection for the default branch. At minimum:

- require changes to arrive through a pull request;
- require conversations to be resolved before merging;
- require the repository's mandatory status checks;
- prevent bypass except for an intentional emergency path.

A formal one-approval rule works only when someone other than the pull-request author can submit an approving review. In a solo repository where the owner account also authors pull requests, use a bot or service account for authored changes before requiring owner approval; GitHub does not count self-approval. Until that separation exists, require explicit owner authorization operationally and keep conversation resolution enforced technically.
