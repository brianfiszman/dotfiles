---
name: agent-memory-hygiene
description: Keep agent state, worklogs, skills, ADRs, and incident records short, current, and non-contradictory.
---

# Agent memory hygiene

## Purpose

Agent memory exists to make the next session faster, not to preserve a
transcript. When memory files grow, stale claims become indistinguishable from
current evidence, and a paused task can look active. Keep each artifact small
and give history a deliberate home.

## Where information belongs

| Information | Canonical home |
|---|---|
| Current task, branch, PR, evidence, next action | `AGENT_STATE.md` on `master` |
| Durable discovery, failed approach, decision rationale over time | Monthly log in `docs/agent-log/` |
| Scope, acceptance criteria, discussion | GitHub issue |
| Implementation, review, exact CI evidence | Pull request and workflow run |
| Reusable procedure or operational rule | Existing specialist skill |
| Durable architecture or process decision | `docs/decisions/NNNN-*.md` |
| Root cause, timeline, hard-won failure detail | `docs/incidents/*.md` |
| Open-work index | `docs/neovim-modernization-backlog.md` (thin) |

Do not duplicate the same content across artifacts. Link to the canonical record.

## Budgets

- `AGENT_STATE.md`: **40 lines maximum**.
- `AGENT_WORKLOG.md`: a **pointer only**, never the log itself.
- Monthly log: scannable; link out instead of pasting diffs or full logs.
- Skill: **300 lines maximum**. If it grows beyond that, split procedural
  guidance from historical fingerprints.
- Backlog: a thin index. Issues are canonical; completed-work prose goes to the
  PR, log, or incident record.

Budgets are review triggers, not formatting preferences. If a file exceeds its
budget, fix it in the same docs PR.

## State ownership and authorization

- `AGENT_STATE.md` on `master` is canonical. Functional branches do not edit it.
- State-only updates land through a dedicated docs PR. Do not amend a functional
  PR with state edits.
- A branch-local checkpoint or worklog is never authorization to resume paused
  work. Verify live GitHub state first.
- State must describe what is authorized, not what would be convenient. Include
  “no merge authorization” when that is true.

## Rotation procedure

At the start of a month, or when the current monthly file becomes hard to scan:

1. Create `docs/agent-log/YYYY-MM.md` with the standard append-only header.
2. Update the current-month link in `AGENT_WORKLOG.md`.
3. Leave older monthly files untouched; they are archive.
4. Continue appending new entries to the new monthly file.
5. If an old entry is wrong, add a correction entry that links to it.

Do not rewrite history to make it shorter. Move durable detail to an incident or
ADR instead, and leave a link.

## Skill maintenance

- Update an existing skill when the knowledge belongs to its domain. Do not
  create a competing skill.
- Create a new skill only for a reusable procedure, architecture rule, or failure
  pattern that no existing skill owns.
- Keep the frontmatter `name` and `description` accurate; the description is how
  the skill is discovered.
- Link new skills from `AGENTS.md`.
- When trimming a skill, move historical incident detail to `docs/incidents/`
  and leave a one-line reference. Do not simply delete hard-won root causes.
- Preserve scope: a Neovim skill does not own GitHub authorization rules.

## Audit checklist

Run before committing a docs or memory change:

- [ ] No stale SHA, run ID, PR number, or branch name presented as current.
- [ ] No contradiction between `AGENTS.md`, the state file, and the skills.
- [ ] No branch-local state presented as authorization.
- [ ] State is 40 lines or fewer and has an explicit next action.
- [ ] Worklog pointer resolves; the monthly file is append-only.
- [ ] Every new skill is linked from `AGENTS.md`.
- [ ] Historical detail moved, not silently deleted.
- [ ] No token, credential, or machine-specific absolute path was added.
- [ ] Docs-only changes did not trigger an unnecessary heavy CI run.

## Completion

A memory change is complete when the next session can answer four questions from
the repository alone: what is active, what was verified, what is authorized, and
what happens next.
