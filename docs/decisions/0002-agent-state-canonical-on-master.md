# ADR 0002 — Agent state is canonical on `master`

- **Status:** Accepted
- **Date:** 2026-11-15
- **Incident:** stalled PR #90 and the branch-local checkpoint

## Context

`AGENT_STATE.md` was committed to each work branch. When Brian paused PR #90,
the branch kept a checkpoint that described the task as resumable and in
progress. A later session read that copy, treated it as current, and continued
work that had been paused. The checkpoint had also grown to 92 lines and
duplicated PR history, while `AGENT_WORKLOG.md` reached 597 lines and 92 KB.

Branch-local state has three problems:

1. It describes the task from inside the task, so it tends to keep the task
   alive.
2. It diverges across branches, so "current state" depends on which branch is
   checked out.
3. It turns documentation commits into functional-branch churn and can trigger
   heavy CI for prose.

## Decision

- `AGENT_STATE.md` on `master` is the only canonical checkpoint.
- Functional branches do not edit it. State updates land through a dedicated
  docs PR that changes no runtime files.
- A branch-local copy or worklog is navigation context, never authorization to
  resume paused work.
- `AGENT_STATE.md` stays at 40 lines or fewer and records only current focus,
  verified evidence, blockers, and the next action.
- `AGENT_WORKLOG.md` is a pointer. Monthly logs live under `docs/agent-log/` and
  are append-only; corrections are new entries.
- Durable history moves to `docs/incidents/`; durable decisions move to
  `docs/decisions/`.

## Consequences

- Resuming work starts by checking live GitHub state and the `master` checkpoint,
  not by trusting the checked-out branch.
- A paused PR cannot make itself look active by editing its own state file.
- Docs work is reviewable in isolation and does not contaminate a functional PR.
- The checkpoint can lag the latest action until the docs PR merges; the GitHub
  record remains authoritative.

## Enforcement

Reviewers check that functional PRs do not touch `AGENT_STATE.md` or the monthly
worklog. A future CI check can reject those paths outside a docs PR, but the rule
is enforced by review until that check exists.
