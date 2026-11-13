---
name: github-project-management
description: Manage this repository's GitHub backlog, branches, and pull requests without duplicating work or losing changes across executions.
---

# GitHub project management

## Goal

Keep project work understandable, traceable, and continuous across separate
sessions and agents. GitHub and the repository are the durable project record;
conversation history is context, not the source of truth.

## Recover the current state first

Before creating, closing, editing, or implementing project work:

1. Inspect the current repository state and branch when local access is available.
2. Read `AGENTS.md` and the skill relevant to the task.
3. Inspect the epic and its linked functional issues.
4. Search relevant open and recently closed issues. Read their bodies, labels,
   state reasons, and comments when they affect the decision.
5. Inspect open PRs and recently closed PRs that touch the same area. Check
   their base/head branches, head commits, changed files, and review context.
6. Confirm branch heads before writing. Do not rely on a SHA or status remembered
   from an earlier execution.

Do not assume a previous artifact is absent because it is not in the current
conversation. Search before creating anything.

## Functional issue design

An issue should describe a behavior or outcome that the maintainer can recognize,
not just an implementation task.

Include:

- **Current behavior:** what happens now.
- **Expected behavior:** what should happen instead.
- **Why it matters:** the user-visible consequence.
- **Scope:** likely affected areas, without over-prescribing the implementation.
- **Acceptance criteria:** observable conditions that determine completion.
- **Validation:** the checks needed and whether they are static, automated,
  headless, full integration, or manual.

Create separate issues only when the behaviors can be implemented and verified
independently. Keep closely related work together when splitting it would make
the backlog harder to understand.

Before creating an issue:

- Search by behavior and outcome, not only exact title words.
- Check closed issues too; they may contain a previous fix, rejection, or
  duplicate relationship.
- Reuse or update an existing issue when it tracks the same result.
- Create a new issue only for a genuinely distinct outcome.
- Close an issue as duplicate or not planned only when the relationship or
  reasoning is clear and documented.

Use plain language in titles and descriptions. Avoid vague tickets such as
"improve config" or overly implementation-specific titles that hide the
behavior being fixed.

## Branch and pull request workflow

- Use a focused topic branch for a coherent piece of work.
- Keep the default branch unchanged until a reviewed PR is merged.
- Link the functional issue from the branch/PR where practical.
- Keep PR scope aligned with its issue or clearly explain when it covers a
  small, cohesive foundation spanning several issues.
- Do not merge a PR unless the user explicitly asks for the merge.
- Do not delete a branch merely because its PR is closed. First establish that
  its unique work is no longer needed.

## Stacked pull requests and scope control

Do not grow an infrastructure/foundation PR with unrelated functional work just
because the same files are involved.

- Prefer a separate topic branch and PR for an independently testable issue.
- If the new change genuinely depends on an unmerged PR, create a **stacked PR**
  whose base is the parent PR's branch. State the dependency in the child PR and
  keep the child diff limited to its own issue.
- Do not create a stacked PR merely for convenience when the work can target the
  default branch independently.
- Never merge the child before its parent. After the parent merges, retarget the
  child PR to the default branch, refresh its diff, and validate it against the
  resulting base.
- Record parent/child PR links in the issue and backlog so another session does
  not mistake the dependency for a duplicate PR.
- Keep the parent branch stable while a child PR is being prepared; re-check its
  head SHA before branching and before opening the child PR.

## Pull request overlap and duplicate audit

Similar titles, descriptions, or goals do not prove that two PRs contain the
same work. Before declaring PRs duplicates or choosing one as canonical:

1. Fetch metadata for both PRs: state, draft status, base branch/SHA, head
   branch/SHA, merge status, and commit counts.
2. Compare each head against its base and compare the two candidate branches
   directly. Inspect merge base, ahead/behind counts, and whether histories
   diverge.
3. List changed files for each PR.
4. Inspect the actual patches or file contents. Filenames and PR summaries alone
   are insufficient.
5. Identify:
   - changes present in both PRs;
   - changes present only in candidate A;
   - changes present only in candidate B;
   - conflicting implementations of the same behavior;
   - changes that belong to separate functional issues.
6. Choose a canonical PR based on scope, correctness, reviewability, and current
   project direction, not merely commit count or which PR is newer.
7. Before closing the other PR, decide what happens to every unique change:
   preserve its branch for later review, port it to the canonical branch, or
   explicitly reject it with a reason.
8. Document the decision in the affected PRs and the parent epic or tracking
   issue. State clearly which work was not merged or incorporated.

Never describe a change as incorporated unless the target branch actually
contains it. Closing a PR is not the same as merging it, and preserving a branch
does not mean its changes have been accepted.

## Review and classify preserved work

A change that exists only on a preserved branch is **unreviewed work**, not
automatically approved work. Do not port every unique diff merely to avoid
losing it.

For each unique change, compare the actual patch with the relevant issue's
expected behavior and acceptance criteria. Check the surrounding implementation
and whether the change introduces a separate behavior or broadens scope.

Assign exactly one working disposition:

| Disposition | Meaning | Next action |
|---|---|---|
| **Accept and port** | The change is correct, needed, and meets an existing issue's criteria | Port it and validate it on the canonical branch |
| **Track separately** | The change may be useful but is outside the current PR/issue scope | Link an existing issue or create one if the outcome is genuinely new |
| **Investigate** | The evidence is incomplete or behavior is uncertain | Reproduce, inspect upstream contracts, or ask for targeted validation |
| **Reject** | The change is incorrect, harmful, or conflicts with the intended behavior | Do not port it; record the technical reason |
| **Already covered** | The canonical branch already provides the same behavior | Do not port duplicate implementation |

For each preserved change, record its file/path, intended behavior, disposition,
reason, and destination (issue or PR). Reassess the disposition if new evidence
appears.

Keep these distinctions explicit:

- **Unique** means only that a diff exists in one branch.
- **Useful** means there is a substantiated benefit.
- **Correct** means the implementation matches the relevant contract and does
  not introduce regressions.
- **Accepted** means it was deliberately selected for the project.
- **Ported** means it is actually present in the destination branch.

Never infer one of these states from another.

## Execution continuity

At the end of a meaningful work session, leave durable state:

- Update the issue/PR description or add a concise comment when a decision,
  blocker, or handoff would otherwise exist only in conversation.
- Keep the epic and functional backlog aligned with the actual state.
- Record the canonical PR and any preserved branches when work is consolidated.
- Record the disposition of unique changes so they are not silently forgotten
  or accidentally treated as approved.
- Distinguish completed changes from proposed changes and unverified work.
- Identify the next concrete action without claiming it has already happened.

Do not create a status issue or extra documentation file when an existing epic,
issue, PR, or backlog is the right place.

## Parent issues and independently testable work

Use a parent/tracking issue when one user goal contains several independently
implementable behaviors, but do not force those behaviors into one oversized
acceptance checklist.

- Search open and closed issues before splitting. Preserve prior decisions and
  closed-duplicate relationships; do not reopen a superseded issue merely
  because it contains useful wording.
- Create one child issue per independently testable user-visible behavior.
  Give each child its own scope, acceptance criteria, and validation plan.
- Keep the parent issue as coordination only: link its children, describe the
  shared goal and boundaries, and state when the parent can close.
- Avoid duplicating the full child acceptance criteria in the parent. Changes
  should be tracked and closed on the child; the parent closes after all children
  are merged and validated.
- When splitting an existing issue, update its body and the functional backlog
  in the same work session. Preserve its existing intent; do not silently drop
  scope that is still valuable.
- Do not create a second umbrella for the same outcome. Link older duplicate
  issues as historical decisions instead.

Example in this repository: issue #43 now coordinates three distinct work
streams—Neotest (#74), DAP (#75), and Telescope (#76). Older #18 and #63 remain
closed as duplicates of #43. DAP Run with Args (#40) remains a separate bug and
must not be merged into the DAP lazy-loading ticket.

## Backlog status and issue sequencing

Keep implementation, validation, merge, and issue closure as separate states:

- **Planned:** no implementation has started.
- **In progress:** work is actively being changed or investigated.
- **Implemented in PR:** the branch contains a candidate fix, but it is not merged.
- **Validated in PR:** the exact PR head has passed the required checks; the issue still remains open until merge.
- **Merged:** the default branch contains the accepted change.
- **Closed:** close only after the merged implementation or an explicit documented decision satisfies the issue.

For the functional backlog, add a short handoff section when several issues are
implemented in one still-open PR. Link the exact PR head and validation run,
identify which issue is next, and state what remains unverified. Do not mark
items complete merely because the current branch contains code for them.
After each merge, reconcile the issues and backlog against the default branch.

When selecting the next issue, prefer a small, independently testable behavior
that is already understood over broad cleanup. Do not create a new issue when an
existing open ticket already describes the desired user-visible outcome.

## Validation and status accuracy

Use precise status language:

- **Not run:** no execution took place.
- **Unavailable:** the environment could not perform the check.
- **Mocked:** a substitute or stub exercised orchestration, not the real service.
- **Passed:** the actual check ran and succeeded.
- **Failed:** the actual check ran and failed.
- **Pending:** a required check has not yet produced a result.

A missing CI run is not a passing run and is not necessarily a failing run.
A successful static check does not prove runtime behavior. Report the exact
commit and validation level when those details matter.

## Completion report

Summarize work in terms the maintainer can act on:

1. What changed, with links to the relevant issues, commits, or PRs.
2. What was deliberately not changed or preserved for later, including the
   disposition of unique branch work.
3. Which checks actually ran and their results.
4. What remains unverified or blocked.
5. The next concrete step, if one is needed.

Do not claim that work is complete merely because files or GitHub artifacts
were created. Verify their final state after writing.


## GitHub Actions evidence and handoff

When a PR's readiness or a CI failure is part of the decision, follow
`.agents/skills/github-actions-validation/SKILL.md` and:

- Anchor every status to the exact current PR head SHA.
- Inspect workflow runs by event. A PR-triggered run does not prove that the
  corresponding push-triggered run exists or passed.
- Treat integration output as a potentially filtered view. In this repository,
  `fetch_commit_workflow_runs` returned only `pull_request` runs and omitted
  `push` runs; never infer "no run" from that helper alone.
- Read job steps and failure logs. If the job is still running and logs are not
  available yet, report pending rather than inventing a cause.
- Record the incident, mitigation commit, exact run IDs, and unresolved status
  in the relevant skill and existing issue/PR. Do not open a new issue just to
  store an execution transcript when the existing functional issue already
  describes the outcome.
- A documentation-only commit can move the PR head without triggering a
  path-filtered runtime workflow. State which code SHA the runtime result
  actually covers, and separately review the later documentation diff.


## Incident fingerprint — closed PR #67 recovery (2026-11-13)

When PR #67 (`chore/neovim-setup-and-ci`) was closed in favor of PR #71, the branch was preserved but its unique runtime changes were not all carried forward. The recovery audit established these rules:

- Compare the complete per-file patch of the closed PR with the canonical PR branch; do not infer completeness from overlapping file names or similar PR descriptions.
- Classify each unique change explicitly: port, keep as separate backlog work, reject with evidence, or record as an intentional omission.
- In this incident, the Neovim 0.11 version guard and removal of unconditional `helptags ALL` were valid and were ported into PR #71. The latter also received a manual repair instruction in README.
- The CI-only mutations of plugin specs, plugin config callbacks, native build hooks, and Treesitter parser updates were intentionally rejected. They weakened the test by skipping real build behavior; PR #71 instead restores locked plugins and starts the normal config without CI-only plugin mutations.
- The proposed grouped lazy.nvim spec rewrite was rejected because inspection of the exact locked lazy.nvim revision proved the existing grouped form valid; issue #68 was closed as not planned.
- Old tickets #46–#65 were duplicates/superseded by canonical issues #26–#45, not completed work. Issue #66 remained open for Python provider runtime validation.
- An optional installer convenience flag (`--sync-plugins`) was not carried forward because first launch already installs plugins and no separate user requirement was established. Record such omissions rather than silently treating them as equivalent.

Never close a competing PR until every unique file-level change and every ticket it introduced has an explicit disposition.
