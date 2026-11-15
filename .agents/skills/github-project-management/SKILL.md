---
name: github-project-management
description: Manage this repository's GitHub backlog, branches, and pull requests without duplicating work or losing changes across executions.
---

# GitHub project management

## Goal

Keep project work understandable, traceable, and continuous across sessions and
agents. GitHub and the repository are the durable project record; conversation
history is context, not the source of truth.

## Recover the current state first

Before creating, closing, editing, or implementing work:

1. Inspect the repository state and branch when local access is available.
2. Read `AGENTS.md` and the skill relevant to the task.
3. Inspect the epic and its linked functional issues.
4. Search open and recently closed issues. Read bodies, labels, state reasons,
   and comments that affect the decision.
5. Inspect open and recently closed PRs touching the same area. Check base/head
   branches, head commits, changed files, and review context.
6. Confirm branch heads before writing. Do not rely on a remembered SHA.

Do not assume an artifact is absent because it is not in the current
conversation. Search before creating anything.

## Functional issue design

An issue should describe a behavior the maintainer can recognize, not just an
implementation task. Include:

- **Current behavior:** what happens now.
- **Expected behavior:** what should happen instead.
- **Why it matters:** the user-visible consequence.
- **Scope:** likely affected areas, without over-prescribing implementation.
- **Acceptance criteria:** observable conditions that determine completion.
- **Validation:** static, automated, headless, full integration, or manual.

Create separate issues only when the behaviors can be implemented and verified
independently. Keep closely related work together when splitting makes the
backlog harder to understand.

Before creating an issue:

- Search by behavior and outcome, not only exact title words.
- Check closed issues; they may contain a previous fix, rejection, or duplicate.
- Reuse or update an existing issue that tracks the same result.
- Create a new issue only for a genuinely distinct outcome.
- Close as duplicate or not planned only when the relationship is documented.

Use plain language. Avoid vague tickets such as "improve config" or
implementation-specific titles that hide the behavior.

### Testing in every task

Testing is included when an issue is created or refined; it is not a follow-up
task and belongs in the estimate and Definition of Done.

Every functional issue must:

- Describe observable scenarios, including negative, edge, and regression cases.
- Name the automated validation: unit, integration, or end-to-end as appropriate.
- For editor work, prefer real headless Neovim tests with the actual
  configuration and real event/plugin/LSP/tool integration.
- Identify focused tests and the broader regression suite. Required checks must
  be wired to explicit PR/path triggers.
- State exact manual steps only for behavior that cannot reasonably be automated.

An issue is not complete because code compiles. It is complete when the required
behavioral tests exist and pass on the exact change, CI passes, and the handoff
records passed, failed, skipped, mocked, and unverified coverage. Docs-only
changes may use diff/Markdown review.

## Branch and pull request workflow

Classify the PR before opening it:

| Type | Scope | Parallel allowed |
|---|---|---|
| **Functional** | Runtime behavior, tests, workflow, installer | One at a time |
| **Docs** | `docs/**`, `AGENTS.md`, state, worklogs, skills | Yes, if it touches no runtime files |
| **Maintenance** | Tooling, CI refactor, dependency update | Treat as functional for WIP limits |

- Use a focused topic branch for a coherent piece of work.
- Keep the default branch unchanged until a reviewed PR is merged.
- Link the functional issue from the branch/PR where practical.
- Keep PR scope aligned with its issue, or explain a small cohesive foundation.
- Do not merge a PR unless Brian explicitly asks for the merge.
- Do not delete a branch merely because its PR is closed. First establish that
  its unique work is no longer needed.
- Do not mix state/worklog edits into a functional PR. They belong in a docs PR.

## Stacked pull requests

Do not grow an infrastructure/foundation PR with unrelated functional work just
because the same files are involved.

- Prefer a separate topic branch and PR for an independently testable issue.
- If the change genuinely depends on an unmerged PR, create a stacked PR whose
  base is the parent branch. State the dependency and keep the child diff limited
  to its issue.
- Do not stack merely for convenience when the work can target the default branch.
- Never merge the child before the parent. After the parent merges, retarget the
  child to the default branch and validate against the resulting base.
- Record parent/child links in the issue and backlog.
- Keep the parent branch stable while preparing a child; re-check its head before
  branching and before opening the child.

## One-functional-PR cadence

1. Finish the current issue scope; do not expand it with unrelated backlog work.
2. Review the complete diff and verify the latest PR head with required checks.
3. Merge only after Brian authorizes it and the exact head is clean.
4. After merge, reconcile the default branch and close only issues satisfied by
   the merged code and validation.
5. Update the backlog with the merge commit, validation run, completed issues, and
   next ticket.
6. Only then start the next functional PR.

Preserve branches for dependent or unrelated work, but do not keep multiple
functional PRs in flight merely because the branches exist. Before reusing a
branch created before a squash merge, compare its unique diff against the old PR
head and the new default branch. Port only reviewed unique work onto a clean
branch; do not carry old PR history forward.

Do not close an issue because a branch contains a candidate implementation.
Closure follows merge plus acceptance evidence.

## Duplicate and overlap audit

Similar titles or goals do not prove two PRs contain the same work. Before
declaring duplicates or choosing a canonical PR:

1. Fetch metadata: state, Draft status, base/head branch and SHA, merge status,
   commit counts.
2. Compare each head against its base and compare the branches directly. Inspect
   merge base, ahead/behind, and divergence.
3. List changed files for each PR.
4. Inspect actual patches or file contents. Filenames and summaries are not
   enough.
5. Identify shared changes, unique changes in each candidate, conflicting
   implementations, and changes belonging to separate issues.
6. Choose canonical based on scope, correctness, reviewability, and project
   direction, not commit count or recency.
7. Before closing the other PR, decide every unique change: preserve the branch,
   port it, or reject it with a reason.
8. Document the decision in both PRs and the parent epic/issue. State what was not
   merged.

Never describe a change as incorporated unless the target branch contains it.
Closing a PR is not merging it; preserving a branch is not accepting its changes.

## Classify preserved work

A change that exists only on a preserved branch is **unreviewed work**. Do not
port every unique diff merely to avoid losing it. Compare the patch with the
relevant issue's expected behavior and acceptance criteria.

Assign exactly one disposition:

| Disposition | Meaning | Next action |
|---|---|---|
| **Accept and port** | Correct, needed, meets an existing issue | Port and validate on the canonical branch |
| **Track separately** | May be useful but outside current scope | Link or create an issue for the outcome |
| **Investigate** | Evidence incomplete or behavior uncertain | Reproduce, inspect upstream, or ask for targeted validation |
| **Reject** | Incorrect, harmful, or conflicts with intended behavior | Do not port; record the technical reason |
| **Already covered** | Canonical branch already provides the behavior | Do not port a duplicate |

For each change, record file/path, intended behavior, disposition, reason, and
destination. Keep these distinctions explicit:

- **Unique:** a diff exists in one branch.
- **Useful:** a benefit is substantiated.
- **Correct:** matches the contract and introduces no regression.
- **Accepted:** deliberately selected.
- **Ported:** actually present in the destination branch.

Never infer one state from another.

## Execution continuity

At the end of a meaningful session:

- Update the issue/PR with decisions, blockers, or handoffs that would otherwise
  exist only in conversation.
- Keep the epic and backlog aligned with actual state.
- Record the canonical PR and preserved branches when consolidating.
- Record dispositions so unique work is not silently forgotten or treated as
  approved.
- Distinguish completed, proposed, and unverified work.
- State the next concrete action without claiming it happened.

Do not create a status issue or extra documentation file when an existing epic,
issue, PR, or backlog is the right place.

## Parent issues and independently testable work

Use a parent/tracking issue when one goal contains several independently
implementable behaviors, but do not force them into one oversized checklist.

- Search open and closed issues before splitting. Preserve prior decisions.
- Create one child issue per independently testable user-visible behavior, with
  its own scope, criteria, and validation.
- Keep the parent for coordination: link children, describe the shared goal and
  boundaries, state when it can close.
- Do not duplicate full child criteria in the parent. Track and close on the
  child; close the parent after all children are merged and validated.
- When splitting an existing issue, update its body and the backlog in the same
  session. Do not silently drop valuable scope.
- Do not create a second umbrella for the same outcome.

## Backlog status and sequencing

Keep implementation, validation, merge, and closure separate:

- **Planned:** no implementation started.
- **In progress:** actively being changed or investigated.
- **Implemented in PR:** candidate fix exists; not merged.
- **Validated in PR:** exact PR head passed required checks; issue still open.
- **Merged:** default branch contains the accepted change.
- **Closed:** only after merged implementation or an explicit documented decision
  satisfies the issue.

For the backlog, add a short handoff only when several issues share a still-open
PR. Link the exact PR head and validation run, identify the next issue, and state
what remains unverified. Do not mark items complete because the branch contains
code for them. After each merge, reconcile issues and backlog against the default
branch.

Prefer a small, understood, independently testable behavior over broad cleanup.

## Validation and status accuracy

Use precise labels: **not run**, **unavailable**, **mocked**, **passed**,
**failed**, **pending**.

A missing CI run is not passing and is not necessarily failing. A successful
static check does not prove runtime behavior. Report the exact commit and
validation level when they matter.

## Completion report

1. What changed, with links to issues, commits, or PRs.
2. What was deliberately not changed or preserved, including dispositions.
3. Which checks actually ran and their results.
4. What remains unverified or blocked.
5. The next concrete step.

Do not claim work is complete because files or GitHub artifacts were created.
Verify their final state after writing.

## Actions evidence

When PR readiness or a CI failure affects the decision, follow
`.agents/skills/github-actions-validation/SKILL.md` and:

- Anchor every status to the exact current PR head SHA.
- Inspect runs by event. A PR run does not prove a push run exists or passed.
- Treat connector output as potentially filtered; cross-check run listings.
- Read job steps and logs. If a job is running and logs are unavailable, report
  pending rather than inventing a cause.
- A docs commit can move the PR head without triggering a path-filtered runtime
  workflow. State which code SHA the runtime result covers and review the docs
  diff separately.

Historical disposition example:
[`docs/incidents/pr67-recovery.md`](../../../docs/incidents/pr67-recovery.md).
