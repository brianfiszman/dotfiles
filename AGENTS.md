# Repository working agreement

This repository contains personal dotfiles. Treat installation and local-machine
state as user data, not disposable test fixtures.

## Source of truth

- The repository and live GitHub state are authoritative. Conversation history,
  `AGENT_STATE.md`, skills, and worklogs are navigation aids; verify them.
- When resuming work, inspect the current branch and worktree, then review the
  relevant issues, open and recently closed PRs, branch heads, and changed files.
- Read this file and the relevant skill before making changes.
- Search existing issues and PRs before creating new ones. A closed issue may
  document a previous decision; inspect it instead of assuming the work is absent.
- Do not recreate, overwrite, close, or discard work merely because it is missing
  from the current conversation context.

## Safety rules

- Never run the installer against a real home directory during tests.
- Tests must redirect HOME and all relevant XDG paths into a temporary directory.
  Use `scripts/test-nvim-headless.sh` for the full isolated install and runtime
  integration check.
- Do not delete or overwrite existing editor configuration without creating a
  recoverable, timestamped backup.
- Do not install OS packages from the dotfiles installer. System dependencies
  must be explicit and documented separately.
- Do not commit credentials, API tokens, local virtual environments, caches,
  compiled binaries, or machine-specific absolute paths.
- Do not run a bulk plugin update as part of an unrelated fix.

## Operational limits

These limits exist to stop unbounded branches, CI churn, and memory files that
grow into a second transcript.

- **One functional PR in flight.** Do not open a second functional PR while one
  is under review. A docs-only PR may run in parallel when it touches no runtime
  files, but it still gets its own branch and PR.
- **Stop and reframe after two failed attempts** at the same symptom. Record the
  hypothesis, what was ruled out, and which layer to test next. Do not keep
  stacking fixes or probes on a failing approach.
- **No committed probe files or debug prints.** Experiments belong in a scratch
  file under the temporary directory, or in a single disposable change removed
  before review. A confirmed repro becomes a focused regression test.
- **Batch CI-triggering commits.** Push when a reviewable slice is ready, not
  after every checkpoint edit. Do not re-run heavy integration for prose-only
  changes to `AGENTS.md`, `AGENT_STATE.md`, worklogs, or `docs/**`.
- **Keep memory files small.** `AGENT_STATE.md` stays at 40 lines or fewer.
  `AGENT_WORKLOG.md` points to the current monthly file; older months live under
  `docs/agent-log/`. Skills stay focused; move durable history to
  `docs/incidents/` and durable decisions to `docs/decisions/`.
- **No secrets in the repository or transcript.** Do not print tokens. Prefer an
  authenticated `gh` session; when a token is required, read it from the
  environment without echoing it.

## Authorization

- Merging always requires Brian's explicit approval. Silence, green CI, a Draft
  PR becoming Ready, or an assistant recommendation is not approval.
- Do not mark a Draft PR Ready or merge it without an explicit instruction.
- Paused work stays paused. A branch-local `AGENT_STATE.md` or worklog does not
  authorize resuming it.

## State ownership

- `AGENT_STATE.md` on `master` is canonical. Functional branches do not edit it.
- State-only updates land through a dedicated docs PR, not by amending a
  functional PR. This prevents a branch from rewriting project state or making
  paused work look authorized.
- Worklogs are append-only per monthly file. Corrections are new entries that
  link to the corrected record.

## Change workflow

- Work on a topic branch; keep the default branch untouched until a reviewed PR
  is merged.
- Prefer one independently testable behavior per issue and small reviewable
  changes.
- Write issues in user-visible terms: what currently happens, what should happen,
  and how we will know it is fixed.
- Preserve existing keymaps and workflows unless a ticket explicitly changes
  them.
- Update the README when setup or user-facing behavior changes.
- Keep the functional backlog in `docs/neovim-modernization-backlog.md` as a thin
  index; the issues are canonical.
- Follow `.agents/skills/neovim-maintenance/SKILL.md` for Neovim-specific work.
- Follow `.agents/skills/github-project-management/SKILL.md` when creating,
  updating, comparing, or closing GitHub issues and pull requests.
- Follow `.agents/skills/github-actions-validation/SKILL.md` when inspecting,
  diagnosing, or reporting GitHub Actions workflows and check results.
- Follow `.agents/skills/scrum-team/SKILL.md` when planning or executing sprint
  work, running ceremonies, or applying QA/reviewer quality gates.
- Follow `.agents/skills/diagnostic-experiments/SKILL.md` when a failure is not
  understood and you are about to instrument, probe, or try another fix.
- Follow `.agents/skills/neovim-headless-testing/SKILL.md` when writing or
  debugging a Neovim behavioral test.
- Follow `.agents/skills/agent-memory-hygiene/SKILL.md` when updating state,
  worklogs, skills, ADRs, or incident records.

## Preserving work across branches and PRs

- Similar titles do not prove duplicate code. Compare base, head, merge base,
  commits, changed files, and patches before closing or replacing a PR.
- Identify changes unique to the PR being closed; preserve the branch or
  deliberately port them after review. Never describe unmerged work as merged.
- Classify each unique change as accept-and-port, track-separately, investigate,
  reject, or already-covered.
- Document the canonical PR, the reason for closure, and the disposition of
  unique work.
- Follow `.agents/skills/github-project-management/SKILL.md` for the full audit.

## Validation and reporting

Testing is part of every implementation task's scope, estimate, and Definition of
Done. Define behavior-first acceptance scenarios before implementation, include
the automated proof, and run required checks in CI on explicit triggers.
Interactive Neovim behavior needs real headless tests with the actual
configuration and plugin/LSP/tool triggers; mocks, syntax checks, startup
success, or module-loaded flags alone do not prove it. Manual checks supplement
automation only where automation is not reasonable, with exact steps and a
stated reason.

Choose validation by impact: docs-only gets Markdown/diff review; shell/installer
gets `bash -n` plus isolated dry-run and failure-path checks; Lua/keymaps get
targeted headless checks; plugin, lazy-loading, LSP, Treesitter, and startup
changes get real headless startup and direct behavior assertions;
bootstrap/installer/XDG/CI changes get the full isolated flow; performance
changes need repeatable before/after measurements.

For every level, distinguish static inspection, mocked harness, real startup,
plugin restore, behavioral assertion, and manual macOS interaction. Report exactly
what ran, what passed, and what remains unverified. The detailed matrix is in
`.agents/skills/neovim-maintenance/SKILL.md`; test construction is in
`.agents/skills/neovim-headless-testing/SKILL.md`.

## Execution continuity

For substantial, multi-step work, read `AGENT_STATE.md` and follow
`.agents/skills/execution-continuity/SKILL.md` before acting. The checkpoint is a
navigation aid, not authority over current GitHub state.

- Recover the current branch, worktree, exact HEAD, linked issues/PRs, and
  relevant workflow evidence before continuing. Verify checkpoint claims against
  the live repository and GitHub; never assume a prior session finished an action.
- Update `AGENT_STATE.md` at meaningful milestones, failures, decisions, before
  and after risky operations, and before/after long waits. Keep the immediate
  next action explicit and the file at 40 lines or fewer.
- Append meaningful discoveries, failed attempts, and decisions to the current
  monthly worklog under `docs/agent-log/`. Do not copy full issue/PR discussions
  or rewrite old entries; link to the canonical record instead.
- Commit and push checkpoint/worklog changes through a dedicated docs PR. Never
  write directly to `master`, and do not mix state edits into a functional PR.
- If a tool call or conversation is interrupted, inspect GitHub before retrying
  a mutation. The operation may have succeeded even if its response was lost.
- Distinguish observed, passed, failed, pending, unavailable, mocked, and
  unverified results. A green run for an older SHA does not validate a newer
  branch head.

The continuity skill coordinates the specialist skills; it must not duplicate
their Neovim, GitHub project-management, or Actions procedures.
