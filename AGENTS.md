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

## Mandatory agent preflight gate

This is a hard execution gate, not optional reading guidance. It applies regardless of model size, capability, confidence, or how familiar the task appears. Before the first repository mutation (file edit, test edit, CI change, commit, push, workflow rerun, PR/issue mutation, or merge), recover and consult the project's prior knowledge.

1. At the start of every repository work session or new conversation, follow `.agents/skills/execution-continuity/SKILL.md`, regardless of task size or prior chat context. Read `AGENTS.md`, canonical `master` `AGENT_STATE.md`, the current monthly worklog, and live GitHub state; resolve the active branch/PR and exact SHA before any mutation. Conversation summaries and model memory are navigation hints, never substitutes for repository evidence.
2. Search for prior learning about the same symptom, component, dependency, and failure signature. Search the linked issue and relevant open/closed PRs and review threads; `docs/agent-log/`, `docs/incidents/`, and `docs/decisions/`; specialist skills; existing regression tests; and relevant GitHub Actions runs and complete failure logs. Search by error text and affected file/function, not just by task title.
3. Extract what the project already learned: confirmed root causes, reproductions, fixes, rejected hypotheses, failed approaches, and known limitations. Revalidate each relevant finding against the active branch and exact tested SHA. Reuse confirmed reproductions and do not repeat a rejected approach unless new evidence shows the underlying conditions changed.
4. Record the sources searched, relevant prior findings, and their disposition in the PR's **Agent preflight** section using `.github/pull_request_template.md`. Write `none found after searching ...` only after checking the relevant project sources. Conversation history, model memory, or another assistant's summary never substitutes for repository evidence.
5. Resolve the active branch, issue, PR, exact head SHA, changed paths, workflow IDs, and events from live GitHub state. Read the complete relevant failure log and the source/test at the SHA that actually ran.
6. Before a fix, state one falsifiable root-cause hypothesis and the smallest discriminating automated reproduction. Follow the two-attempt stop rule in `.agents/skills/diagnostic-experiments/SKILL.md`; do not push guesses to use CI as a diagnostic tool.
7. Turn every confirmed reusable failure into a regression test and update its owning skill or incident record. Do not state an unverified hypothesis as fact. Keep canonical state/worklog changes on a separate docs-only PR.
8. Before completion, inspect the full final diff, execute focused and applicable broader tests, re-fetch the exact final PR head, and report only observed exact-SHA evidence. Tests written, mocked, skipped, pending, failed, and passed are different states.

## Context compaction before saturation

Treat working context as a limited execution resource. Compact it proactively
when a session becomes long, tool/output volume grows, the same evidence is being
re-read, reasoning starts looping, an interruption occurs, or the context may
soon be truncated. Do not wait until important state is lost.

When compacting, preserve only what is needed to continue the active task:
1. **Objective and priority:** the user's current goal, explicit priority order,
   acceptance criteria, and constraints.
2. **Live artifact identity:** repository, issue/PR, branch, exact current head
   and base SHAs, and the relevant run IDs/events. Re-fetch live state after
   interruptions or uncertain writes.
3. **Decisions and authority:** user-approved scope, merge/delegation rules,
   stop limits, and actions explicitly not authorized.
4. **Evidence:** verified facts with links and exact-SHA scope; clearly separate
   passed, failed, skipped, pending, unavailable, and not-run work.
5. **Uncertainty and history that changes the next action:** open hypotheses
   labelled unconfirmed, rejected approaches, exhausted attempts, and why they
   must not be repeated.
6. **Next action:** one concrete, smallest discriminating step, its expected
   evidence, and any blocker.

Discard raw logs after extracting the relevant lines, repeated tool output,
superseded state, speculative branches that do not affect the next decision,
and conversational chronology with no continuing value. Do not preserve
chain-of-thought or a transcript; preserve conclusions, evidence, decisions,
and pointers to canonical sources. Never compress away the user's priority,
uncertainty, safety constraints, failed-attempt count, or exact artifact identity.

Prefer updating the existing canonical PR/issue, monthly worklog, or
`AGENT_STATE.md` through its required docs-only PR rather than creating a new
summary file. The monthly worklog is append-only; keep `AGENT_STATE.md` short
and current. A conversation summary is only a navigation aid, not project
evidence. After compaction, continue from the recorded next action without
making the user repeat information or narrating every tool call; report only
meaningful milestones, decisions, or blockers.

This rule supplements, and never bypasses, the mandatory agent preflight,
live-state verification, exact-SHA evidence, and two-attempt diagnostic stop
rules above.

CI validates that every pull request records the required preflight fields and runs the process-contract tests. This detects omitted or malformed records; it cannot prove that an agent genuinely read a source or that a claim in the PR body is truthful. Agents must cite concrete issue, PR, run, file, and test references, and reviewers must challenge unsupported claims. A workflow check only blocks merges when repository branch protection or a ruleset requires that successful check. Before describing this as merge-blocking, inspect the live repository rules; a workflow that runs without a required-status rule is advisory. If a required source, skill, prior incident, or live GitHub state cannot be read, stop the affected mutation and report the blocker as unavailable. Never bypass this gate because the model is sophisticated, the change looks obvious, or the same class of task was handled before.

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
- **Remote-only agents: CI is the only runtime.** Do not use CI to explore
  hypotheses. State the root cause in one sentence before pushing a fix, batch
  related assertions into one run, and make every assertion print expected vs
  actual plus the relevant fixture state. After two failed runs on the same
  symptom, stop and hand off the diagnosis instead of pushing another guess.
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

- Brian has granted the assistant standing authority to mark Draft PRs Ready and
  merge PRs in this repository once the issue's acceptance criteria are met,
  the complete current diff has no blocking findings, required tests and CI pass
  on the exact PR head, the PR is mergeable, and all risk-based QA/reviewer gates
  are satisfied.
- No per-PR merge approval is needed under this delegation. Do not merge when a
  required check is failed, pending, or unavailable; a required manual check is
  incomplete; review findings or product decisions remain unresolved; or any
  blocker exists. Ask Brian about those substantive decisions, not routine
  merge permission.
- Brian retains final authority over priority, scope, and acceptance and may
  change or revoke this delegation at any time.
- Paused work stays paused. A branch-local `AGENT_STATE.md` or worklog does not
  authorize resuming it.

## State ownership

- `AGENT_STATE.md` on `master` is canonical. Functional branches do not edit it.
- State-only updates land through a dedicated docs PR, not by amending a
  functional PR. This prevents a branch from rewriting project state or making
  paused work look authorized.
- Worklogs are append-only per monthly file. Corrections are new entries that
  link to the corrected record.

## Version policy

Default to the latest stable Neovim release and current upstream-supported
plugin APIs. Do not maintain older-version compatibility, legacy branches, or
fallback shims unless Brian explicitly requests them or a current upstream
contract makes them unavoidable. Prefer migrating to the supported API. Keep CI
focused on latest stable; add nightly where useful, not older stable versions by
default. Exact pins are for reproducibility, not for preserving obsolete APIs.

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
- Follow `.agents/skills/neovim-maintenance/SKILL.md` for Neovim-specific work, and its `.agents/skills/neovim-maintenance/references/live-runtime-rpc.md` for read-only inspection of an already-running Neovim session.
- Follow `.agents/skills/neovim-dependency-management/SKILL.md` when triaging `:checkhealth`, provisioning optional tools/providers, or comparing local and CI dependency state.
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
- Follow `.agents/skills/automated-verification/SKILL.md` for every task
  requiring behavioral verification; automate and execute every feasible
  reproduction yourself before declaring completion or asking Brian to test.
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
Done. For every acceptance criterion that requires reproducing behavior, build
or reuse an automated reproduction and execute it yourself, locally or through
an inspected CI run. Writing a test is not enough: report only tests that
actually ran on the exact final SHA. Drive the real user-facing trigger and
assert observable behavior; a mock, lower-level protocol event, syntax check,
startup success, or module-loaded flag does not prove a higher-level path.

Do not ask Brian to perform a reproduction that can reasonably be automated.
Before proposing a manual check, investigate real UI/PTY input, OS/protocol
event injection, emulators, virtual devices, local services, and CI execution.
A lack of local GUI/device access is a tooling constraint, not proof that a test
is impossible. Manual verification is a narrow exception for irreducibly
external behavior only; explain why each automation route is insufficient,
identify exactly what remains unverified, and do not mark the task complete or
merge while a required gate remains open.

Interactive Neovim behavior needs tests with the actual configuration and
plugin/LSP/tool trigger. When terminal behavior is under test, prefer a real
PTY/TUI and the actual terminal input sequence over directly sending the
Neovim RPC event that the TUI is supposed to produce. Mocks may isolate an
external service, but must not substitute for an available real integration
path. Keep test data isolated and retain confirmed reproductions as regression
tests with explicit CI triggers.

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
