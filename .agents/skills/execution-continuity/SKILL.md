---
name: execution-continuity
description: Recover and preserve multi-step repository work across interrupted prompts, tool failures, and new agent sessions using verified checkpoints and an append-only work log.
---

# Execution continuity

## Purpose

Make an interrupted work session recoverable without depending on conversation
history. The repository and its live GitHub state are the source of truth.
`AGENT_STATE.md` is a compact handoff pointer; `AGENT_WORKLOG.md` preserves
meaningful discoveries and decisions over time. Neither file replaces issues,
pull requests, commits, specialist skills, or CI evidence.

This skill coordinates specialist skills. It does not copy their technical
procedures.

## Recovery sequence

Follow this sequence before continuing substantial work:

1. Read `AGENTS.md` and this skill.
2. Read `AGENT_STATE.md`. Note the repository, branch, base, last recorded
   HEAD, active issue/PR, phase, blockers, and next action.
3. Read the latest entries at the end of `AGENT_WORKLOG.md`. Follow links to
   existing issues, PRs, commits, and CI runs for detailed context; do not
   reconstruct those discussions from memory.
4. Inspect the actual repository state:
   - With a local checkout, run `git status --short --branch`,
     `git rev-parse HEAD`, and inspect the configured remotes before editing.
   - With GitHub-only access, resolve the current branch ref and fetch its
     current commit, the linked issue/PR, changed files, review threads, and
     relevant workflow runs.
5. Compare the recorded checkpoint with the live branch and GitHub state.
   Verify whether the recorded PR is still open, merged, or closed; whether the
   issue is still open; whether the branch advanced; and whether the cited run
   tested the exact current code SHA and correct event.
6. Inspect the actual changed files and diffs for the active task. A title,
   summary, checkpoint, or prior agent's statement is not a substitute for the
   code or document diff.
7. Reconcile stale or contradictory status in the checkpoint before acting.
   Preserve unmerged branch work. Never assume an operation completed merely
   because the interrupted session attempted it.
8. Continue from the next concrete action only after the state is verified.

### Evidence rules

Use precise status labels:

- **Passed:** the named check ran and succeeded.
- **Failed:** the named check ran and failed.
- **Pending:** the required check has not finished or has not been observed.
- **Unavailable:** the environment or permissions could not perform it.
- **Not run:** no attempt was made.
- **Mocked:** a substitute exercised only the mocked behavior.
- **Unverified:** evidence is incomplete or does not cover the claim.

A workflow run is evidence only for the exact commit, event, and checks it
actually exercised. A green run for an older SHA does not validate a newer
branch head. A pull-request run is not evidence of a separate push event.
Inspect job steps and relevant logs when a check's scope or failure matters.

When the prior session may have been interrupted during a mutation, re-fetch
the resource before retrying. A lost tool response does not prove that GitHub
rejected the write; blind retries can create duplicate issues, comments, or
commits.

## Checkpoint maintenance

Keep `AGENT_STATE.md` short and current. It should answer, without reading the
conversation:

- What repository and task are active?
- Which branch/ref and exact source/work HEAD were last verified?
- Which issue, PR, commit, and workflow run are relevant?
- What phase is the work in?
- What has been completed, and what remains?
- Which validation actually ran, for which SHA and event?
- What is blocked or unavailable?
- What is the next concrete action?

Update the checkpoint at these boundaries:

- Start or resume of a substantial task.
- A meaningful diagnosis, discovery, or change in direction.
- A completed implementation or review milestone.
- Before a risky mutation (for example, changing a branch ref, merging, closing
  an issue, deleting a file, or replacing an artifact) and immediately after
  its result is known.
- Before a long-running wait, including the exact operation and expected
  evidence; update it again when the wait ends.
- When a CI run starts, fails, passes, or is superseded by a newer HEAD.
- Before handing work to another session or ending a substantial session.

Do not checkpoint trivial reads or every small tool call. Prefer a few useful
milestones over a noisy transcript.

For a checkpoint update, record observed facts and clearly label assumptions,
pending work, and unavailable validation. Include exact SHAs, run IDs, event
types, and links where applicable. Do not claim tests or mutations succeeded
until their result is observed.

The commit containing `AGENT_STATE.md` cannot embed its own resulting commit
SHA. Record the exact source/work HEAD used to build the checkpoint and explain
that the exact persisted snapshot is obtained by resolving the named remote
branch ref. On the next recovery, resolve and verify that ref before proceeding.

## Work-log maintenance

`AGENT_WORKLOG.md` is chronological and append-only:

- Add entries for durable discoveries, failed approaches, root-cause evidence,
  technical decisions, risk-bearing operations, and handoffs.
- Include the date, issue/PR/branch, concise event, observed result, and
  implications for the next session.
- Link the canonical issue, PR, commit, run, or specialist skill instead of
  copying long diffs, complete command output, or whole issue discussions.
- Record failed attempts when they teach something or change the next action.
- Never rewrite or silently delete earlier entries. Correct a mistaken entry
  with a newer entry that links to the correction.
- Keep routine command output and trivial reads out of the work log.

The checkpoint is rolling state; the work log is historical context. Do not
turn either into a second backlog or a duplicate copy of the GitHub issue.

## Specialist skill decisions

Create a new specialist skill only when the work reveals a reusable procedure,
architecture rule, or failure pattern that is not owned by an existing skill.

- If the knowledge belongs to an existing specialist's domain, update that
  skill instead of creating a competing one.
- Keep this continuity skill focused on recovery, checkpointing, evidence, and
  coordination; do not duplicate Neovim maintenance, GitHub project
  management, or Actions diagnosis rules.
- When a new skill is justified, give it a clear name and description, link it
  from `AGENTS.md`, and update any repository skill index if one exists.
- There is currently no separate skill index in this repository; `AGENTS.md`
  is the top-level index of required working agreements. If an index is added
  later, register the skill there.
- When changing an existing skill, preserve its scope and link the durable
  incident or issue that motivated the update.

## Branch, commit, and handoff rules

- Never edit the default branch directly. Work on a topic branch tied to an
  issue or a clearly documented maintenance task.
- Commit checkpoint and work-log updates on the active work branch so the
  information survives loss of the local environment or conversation.
- Push the branch and verify the remote ref and file contents after meaningful
  persistence milestones.
- Avoid unnecessary commits for trivial activity, but do not leave a
  checkpoint only in an unpushed local worktree at the end of a substantial
  task.
- Follow `github-project-management` for issue/PR deduplication, comparisons,
  branch protection, merge authorization, and closure rules.
- Follow `github-actions-validation` for exact-SHA/event validation and log
  inspection.
- Follow `neovim-maintenance` for Neovim configuration and runtime work.
- Do not merge a PR or close an issue unless its acceptance criteria and the
  repository's authorization rules are satisfied.

## Suggested formats

Use this structure in `AGENT_STATE.md` and adapt it to the task:

```markdown
# Agent execution state

_Last updated: YYYY-MM-DD_

## Current task
- **Status:**
- **Repository:**
- **Branch:**
- **Base / last verified HEAD:**
- **Issue / PR:**
- **Phase:**

## Completed and verified
- ...

## Pending
- ...

## Validation
| Check | Status | Exact SHA / event / run |
|---|---|---|
| ... | ... | ... |

## Blockers
- ...

## Next concrete action
...
```

Append work-log entries using dated headings:

```markdown
## YYYY-MM-DD — concise event title

- Context / issue / branch:
- What changed or was discovered:
- Evidence and result:
- Consequence / next action:
```

The files should remain compact enough to scan quickly. Put detailed
acceptance criteria in issues, implementation details in code/PRs, and test
evidence in workflow runs and specialist skills.

## Recovery completion checklist

Before resuming implementation, confirm:

- [ ] The remote branch ref and exact HEAD are known.
- [ ] The checkpoint matches the live branch or its stale fields are corrected.
- [ ] The latest work-log entry and relevant issue/PR have been read.
- [ ] No unmerged unique work or newer commits have been overlooked.
- [ ] CI claims match the exact SHA, event, and observed job result.
- [ ] The next action is explicit and does not repeat completed work.
