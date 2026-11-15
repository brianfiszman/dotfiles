---
name: execution-continuity
description: Recover and preserve multi-step repository work across interrupted prompts, tool failures, and new agent sessions using canonical state and monthly logs.
---

# Execution continuity

## Purpose

Make an interrupted session recoverable without depending on conversation
history. The repository and live GitHub state are the source of truth.
`AGENT_STATE.md` is a compact handoff pointer; the monthly log under
`docs/agent-log/` preserves durable discoveries. Neither replaces issues, pull
requests, commits, or CI evidence. This skill coordinates specialist skills; it
does not copy their procedures.

## Canonical state

- `AGENT_STATE.md` on `master` is the only canonical checkpoint.
- Functional branches do not edit it. State updates land through a dedicated
  docs PR that changes no runtime files.
- A branch-local copy or worklog is navigation context, never authorization to
  resume paused work. See `docs/decisions/0002-agent-state-canonical-on-master.md`.
- Keep the checkpoint at 40 lines or fewer. If it grows, move history to the
  monthly log, an incident record, or the issue/PR.

## Recovery sequence

1. Read `AGENTS.md`, this skill, and the `master` copy of `AGENT_STATE.md`.
2. Read the tail of the current monthly log under `docs/agent-log/`. Follow links
   to issues, PRs, commits, and runs; do not reconstruct them from memory.
3. Inspect the actual local state: `git status --short --branch`,
   `git rev-parse HEAD`, remotes, and the configured upstream.
4. Resolve the live GitHub state: branch ref, linked issue/PR, changed files,
   review threads, and relevant workflow runs.
5. Compare the checkpoint with live state. Verify whether the PR is open, merged,
   or closed; whether the issue is open; whether the branch advanced; and whether
   the cited run tested the exact current SHA and event. If the PR is closed or
   superseded, follow its disposition link and treat the replacement as active.
6. Read the actual diff for the active task. A title, summary, checkpoint, or
   prior agent's statement is not evidence.
7. Reconcile stale fields before acting. Preserve unmerged branch work. Never
   assume an operation completed because the interrupted session attempted it.
8. Continue from the next concrete action only after the state is verified.

## Active artifact resolution

A run describes the artifact it actually tested, not whichever PR is convenient:

- A closed or merged PR is historical. Follow its disposition/replacement link;
  never report its runs as the active branch's current status.
- Use the active PR's `headRefName` and `headRefOid`. Archive branches, aliases,
  and similarly named branches are not active merely because they still exist.
- Match every run's `head_sha` to the active head. Older runs are historical
  evidence; a green run does not cover commits added afterward.
- If GitHub state or run data is unreachable, label it **Unavailable** and stop.
  Do not infer current status from a local branch, an older run, or memory.

## Evidence labels

Use precise labels:

- **Passed:** the named check ran and succeeded.
- **Failed:** the named check ran and failed.
- **Pending:** the required check has not finished or has not been observed.
- **Unavailable:** the environment or permissions could not perform it.
- **Not run:** no attempt was made.
- **Mocked:** a substitute exercised only the mocked behavior.
- **Unverified:** evidence is incomplete or does not cover the claim.

A run is evidence only for the exact commit, event, and checks it exercised. A
green older SHA does not validate a newer branch head. A pull-request run is not
evidence of a push event. Inspect job steps and logs when scope or failure
matters.

When a mutation may have been interrupted, re-fetch the resource before
retrying. A lost tool response does not prove GitHub rejected the write; blind
retries create duplicates.

## Checkpoint maintenance

Update `AGENT_STATE.md` when:

- a substantial task starts or resumes;
- a meaningful diagnosis, discovery, or direction change occurs;
- an implementation or review milestone completes;
- before and after a risky mutation (branch ref, merge, close, delete);
- before and after a long wait, including the exact operation and expected
  evidence;
- a CI run starts, fails, passes, or is superseded;
- work is handed to another session or a substantial session ends.

Do not checkpoint trivial reads or every tool call. Record observed facts and
label assumptions, pending work, and unavailable validation. Include exact SHAs,
run IDs, event types, and links. Do not claim a test or mutation succeeded until
its result is observed.

The commit containing `AGENT_STATE.md` cannot embed its own resulting SHA. Record
the source/work HEAD used to build the checkpoint and resolve the named remote
ref on the next recovery.

## Work-log maintenance

`AGENT_WORKLOG.md` is a pointer to the current monthly file under
`docs/agent-log/`. Each monthly file is chronological and append-only:

- Add entries for durable discoveries, failed approaches, root-cause evidence,
  technical decisions, risk-bearing operations, and handoffs.
- Include the date, issue/PR/branch, concise event, observed result, and the
  consequence for the next session.
- Link the canonical issue, PR, commit, run, or skill instead of copying diffs,
  full command output, or whole discussions.
- Record failed attempts when they teach something or change the next action.
- Never rewrite or silently delete earlier entries. Correct a mistaken entry with
  a newer entry that links to the correction.
- Keep routine command output and trivial reads out of the log.

Rotate at the start of a new month: create `docs/agent-log/YYYY-MM.md`, update
the pointer in `AGENT_WORKLOG.md`, and leave older months untouched. See
`.agents/skills/agent-memory-hygiene/SKILL.md`.

## Authorization

- Merging requires Brian's explicit approval. Silence, green CI, a Draft PR
  becoming Ready, or an assistant recommendation is not approval.
- Do not mark a Draft PR Ready or merge it without an explicit instruction.
- Paused work stays paused regardless of what a branch-local checkpoint says.
- Do not close an issue or PR unless its acceptance criteria and the
  repository's authorization rules are satisfied.

## Handoff rules

- Work on a topic branch; never edit `master` directly.
- Follow `github-project-management` for deduplication, comparison, branch
  protection, and closure rules.
- Follow `github-actions-validation` for exact-SHA/event validation and logs.
- Follow `neovim-maintenance` and `neovim-headless-testing` for runtime work.
- Push through a dedicated docs PR for state/log updates. Do not mix them into a
  functional PR.
- Avoid unnecessary commits, but do not leave a checkpoint only in an unpushed
  local worktree at the end of a substantial task.

## Recovery checklist

- [ ] Remote branch ref and exact HEAD are known.
- [ ] The active issue/PR is open, or its replacement is identified.
- [ ] The `master` checkpoint matches live state, or its stale fields are noted.
- [ ] The current monthly log and relevant issue/PR have been read.
- [ ] No unmerged unique work or newer commits were overlooked.
- [ ] CI claims match the exact active head, event, and observed job result.
- [ ] The next action is explicit and does not repeat completed work.
