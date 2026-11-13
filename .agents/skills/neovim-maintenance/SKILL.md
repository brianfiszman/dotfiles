---
name: neovim-maintenance
description: Maintain and improve this repository's Neovim configuration safely, with evidence-based diagnosis, functional issues, incremental changes, and honest validation.
---

# Neovim maintenance

## Goal

Improve the actual editing experience without turning the configuration into a
minimal demo or breaking useful workflows. Optimize for predictable startup,
responsive editing, reliable language tooling, and a setup that can be reproduced
on another machine.

## How to work with the maintainer

- Communicate directly and explain the user-visible effect of each technical
  change. Avoid unexplained plugin jargon.
- Prefer a small number of clearly scoped fixes over a sweeping rewrite.
- Explain trade-offs when removing, replacing, or delaying a plugin.
- Be explicit about evidence: a static observation is not a measured performance
  result, and a headless test is not a replacement for testing the Mac UI.
- Never request or use a personal access token when the connected GitHub
  integration is sufficient.
- The maintainer authorizes changes to setup scripts, test scripts, CI, and
  documentation when they are needed to make the setup safer or close a
  validation gap. Do not treat those files as off-limits.

## Start by recovering the real state

Before changing anything:

1. Read `AGENTS.md` and this skill.
2. Inspect the current branch, worktree, and relevant open PR when those are
   available. Do not assume the branch or files still match an earlier run.
3. Read the actual configuration files involved, not only the README or issue.
4. Inspect `lazy-lock.json` before reasoning about installed plugin versions
   or upstream APIs.
5. Trace the relevant startup, loading, or keybinding path far enough to
   understand who owns the behavior and when it runs.
6. Check existing issues and PRs before opening new work. Follow
   `.agents/skills/github-project-management/SKILL.md` for ticket and PR
   deduplication.

Do not call something a bug merely because a pattern looks unusual or could be
simplified. For example, lazy.nvim supports both individual plugin specs and
valid list-style specs; a grouped spec is not inherently invalid. Confirm the
actual API contract and reproduce the reported failure before changing it.

## Diagnosis and evidence

For each proposed fix, record:

- The user-visible problem.
- The evidence that demonstrates it (code path, reproducible failure, upstream
  contract, or measured behavior).
- The smallest relevant scope.
- The behavior that should change and the behavior that must remain unchanged.
- The validation level that can actually be performed.

Do not turn an unverified suspicion into a functional issue. When the diagnosis
is uncertain, investigate first or mark the uncertainty explicitly.

## Issue quality

Create one issue for each independently testable behavior. A good issue contains:

1. **What you notice** — describe the current behavior in plain language.
2. **Desired behavior** — describe what should happen from the user's perspective.
3. **Scope** — list the configuration area or files likely involved.
4. **Acceptance criteria** — concrete checks that prove the behavior changed.
5. **Validation** — say whether the check is static, headless, or requires manual
   interaction.

Avoid tickets such as "clean up Neovim". Prefer a ticket like "Opening a file
should not start the AI completion plugin until the user enters Insert mode".

Before creating an issue, search open and relevant closed issues and inspect
related PRs. Reuse or update an existing ticket when it tracks the same outcome.
Close an incorrect ticket as not planned only after checking the implementation
or source that disproves it.

## Safe installation rules

- The installer must never call `sudo`, `apt`, `pacman`, or another system
  package manager.
- The default install target is Neovim only. Emacs is opt-in.
- Existing targets are moved to unique, timestamped backups before replacement.
- Stage files before swapping them into place; attempt to restore the backup if
  the final move fails.
- Exclude `.config/nvim/venv` from installation. A virtualenv is generated for
  one machine and must never be copied to another.
- Keep dry-run behavior available and side-effect free.
- Document optional external providers (such as pynvim) with reproducible
  per-user setup commands rather than committing generated environments.
- Tests must redirect HOME and all relevant XDG directories into a temporary
  directory. Never test installation against the maintainer's real home.

## Neovim test strategy

Choose the strongest available test level and report the level actually reached.
Do not imply that a weaker level proves a stronger one.

1. **Environment discovery:** check whether a real Neovim binary and required
   tools are available. Record their versions when relevant.
2. **Shell syntax:** run `bash -n install.sh` and
   `bash -n scripts/test-nvim-headless.sh` separately.
3. **Static checks:** validate Lua syntax and inspect changed paths, generated
   files, and installer behavior without claiming runtime coverage.
4. **Isolated installer checks:** run setup with temporary HOME and XDG
   directories. Verify dry-run leaves files untouched, existing configs are
   backed up, Neovim-only mode leaves Emacs alone, and generated virtualenvs
   are excluded.
5. **Mocked harness:** use only to verify orchestration or installer logic when
   a real dependency is unavailable. Label the result as mocked; it is not
   proof that Neovim started or that plugins loaded.
6. **Plugin restore with real Neovim:** use `:Lazy! restore` to install the
   versions recorded in `lazy-lock.json`, rather than silently upgrading
   everything. Record network or dependency failures separately from config
   failures.
7. **Real headless startup:** launch the installed configuration again with a
   real Neovim binary and fail on Lua/plugin startup errors. A script named
   "headless test" or a mocked `nvim` executable does not by itself establish
   that this level passed.
8. **Interactive macOS check:** validate terminal rendering, font, clipboard,
   keymaps, LSP attachment, completion, and perceived typing latency on the
   maintainer's Mac.

The automated test is intended to prove that a clean checkout can install and
start in an isolated environment. Confirm what the current script really
executes before describing its coverage. Clearly distinguish an expected CI
check, a missing CI run, a failed CI run, and a passing CI run.

## Setup, CI, and documentation changes

- Improve the setup and test infrastructure when that is the right way to close
  a reproducibility or safety gap.
- Keep CI focused on deterministic checks; do not hide failures by weakening
  assertions or silently skipping unavailable steps.
- Update the README when installation commands, prerequisites, or user-visible
  setup behavior changes.
- Keep `docs/neovim-modernization-backlog.md` aligned with the functional
  issues. Do not create a second backlog in a skill or README.

## Plugin and LSP changes

- Keep plugin declarations readable and explicit. lazy.nvim accepts both
  individual plugin specs and valid list-style specs; do not report a grouped
  list as a bug without reproducing a real missing-plugin failure.
- Keep lazy loading tied to actual use: filetype for language tooling, commands
  or keys for search/debug/test workflows, and insert mode for typing assistants.
- Avoid overlapping providers for scrolling, formatting, linting, highlighting,
  and LSP server setup.
- Preserve `lazy-lock.json` unless a ticket explicitly includes a plugin version
  change.
- Pin or document APIs when upstream plugins make breaking branch migrations.
- Verify optional executables before invoking external linters or formatters.
- Make missing tools produce actionable messages rather than repeated noise.

## Completion criteria

A fix is complete only when:

- Its acceptance criteria pass, or the remaining blocker is explicitly recorded.
- Relevant automated checks pass, or the reason they cannot run is documented.
- The exact validation level and environment are reported honestly.
- The README/backlog is updated when behavior or setup instructions change.
- The user is told what changed, what was tested, and what remains unverified.
