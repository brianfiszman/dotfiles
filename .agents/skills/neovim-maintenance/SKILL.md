---
name: neovim-maintenance
description: Maintain and improve this repository's Neovim configuration safely, with evidence-based diagnosis, behavior-preserving tests, incremental changes, and honest validation.
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

## Version and compatibility policy

Target the latest stable Neovim and current upstream-supported plugin APIs.
Do not maintain older-version support, legacy branches, or compatibility
fallbacks solely for backward compatibility; migrate forward instead. CI
targets latest stable by default, with nightly optional and older versions only
on explicit request. Exact pins are for reproducibility, not obsolete APIs.
Temporary shims must be justified by the latest stable contract and have a
clear removal condition.

## Start by recovering the real state

1. Read `AGENTS.md` and this skill.
2. Inspect the current branch, worktree, and relevant open PR.
3. Read the actual configuration files involved, not only the README or issue.
4. Inspect `lazy-lock.json` before reasoning about installed versions or upstream
   APIs.
5. Trace the startup, loading, or keybinding path far enough to understand who
   owns the behavior and when it runs.
6. Check existing issues and PRs before opening new work.

Do not call something a bug because a pattern looks unusual. For example,
lazy.nvim accepts both individual and valid list-style specs; a grouped spec is
not inherently invalid. Confirm the contract and reproduce the failure first.

## Diagnosis and evidence

For each proposed fix, record:

- The user-visible problem.
- The evidence: code path, reproducible failure, upstream contract, or measured
  behavior.
- The smallest relevant scope.
- The behavior that should change and the behavior that must not regress.
- The validation level that can actually be performed.

Do not turn an unverified suspicion into a functional issue. When diagnosis is
uncertain, timebox an investigation or mark the uncertainty explicitly. Follow
`.agents/skills/diagnostic-experiments/SKILL.md` when a failure resists the first
attempt.
For `:checkhealth` triage, external tool/provider provisioning, and local-versus-CI dependency drift, follow `.agents/skills/neovim-dependency-management/SKILL.md`.

## Review every change as code

- Read the full diff, not just the title, issue, commit message, or summary.
- Inspect surrounding code and the configuration still active outside the diff.
- Look for accidental comments, literal escape sequences, malformed Lua tables,
  overwritten options, duplicate setup calls, and stale names.
- Check that environment-specific branches do not silently change interactive
  behavior.
- Verify test-only conditions are scoped and reset; do not leave a CI variable
  active for normal startup.
- Compare the final files with the issue's acceptance criteria. Unique does not
  mean correct.

## Issue quality

Create one issue per independently testable behavior. A good issue contains:

1. **What you notice** — current behavior in plain language.
2. **Desired behavior** — what should happen from the user's perspective.
3. **Scope** — likely configuration area or files.
4. **Acceptance criteria** — concrete checks that prove the change.
5. **Validation** — static, targeted headless, full integration, or manual.

Avoid tickets such as "clean up Neovim". Prefer "Opening a file should not start
the AI completion plugin until the user enters Insert mode".

Search open and relevant closed issues and inspect related PRs first. Reuse or
update an existing ticket for the same outcome. Close an incorrect ticket as not
planned only after checking the implementation or source that disproves it.

## Safe installation rules

- The installer must never call `sudo`, `apt`, `pacman`, or another system
  package manager.
- The default install target is Neovim only. Emacs is opt-in.
- Existing targets are moved to unique, timestamped backups before replacement.
- Stage files before swapping; attempt to restore the backup if the final move
  fails.
- Exclude `.config/nvim/venv` from installation. A virtualenv is machine-specific.
- Keep dry-run behavior available and side-effect free.
- Document optional external providers with reproducible per-user setup commands.
- Tests must redirect HOME and all relevant XDG directories into a temporary
  directory. Never test installation against the maintainer's real home.

## Behavior-first testing

Testing is part of every issue's scope and estimate. Do not defer it or mark an
implementation complete before its required tests pass.

When creating or refining an issue:

1. Define observable scenarios before implementation: the normal path,
   failure/edge paths, and behavior that must not regress.
2. Name the automated proof. Use unit tests for isolated logic, integration tests
   for real boundaries, and end-to-end tests for complete workflows.
3. For editor behavior, automate the local usage path with a real headless
   Neovim process and the actual configuration/plugins/LSP/tools. Trigger the
   same event, mapping, command, or completion request the maintainer would use,
   then assert the observable result.
4. Syntax checks, mocks, package-loaded flags, command registration, or startup
   success are not proof that an interactive feature works.
5. Include focused tests and the relevant regression suite in CI with explicit
   PR/path triggers. If a test moves to a scheduled/manual workflow, preserve
   equivalent coverage and document the trigger.
6. Isolate HOME/XDG and generated state. Manual Mac verification supplements
   automation; document exact steps only where automation is not reasonable.

## Select tests by change impact

| Change type | Minimum useful validation |
|---|---|
| Documentation-only | Markdown/diff review; no Neovim run required |
| Shell script or installer | `bash -n`, isolated dry-run, focused install/backup tests |
| Lua-only logic or keymap | Lua syntax and targeted headless check |
| Plugin spec, lazy loading, LSP, Treesitter, startup | Real headless startup; add plugin restore when dependencies or lockfile are involved |
| Bootstrap, installer flow, XDG paths, CI harness | Full isolated integration: install, restore locked plugins, normal startup |
| Performance optimization | Repeatable before/after measurement under the same conditions, plus regression checks |

When a required dependency is unavailable, run the strongest useful lower-level
checks and state exactly what remains unverified. Do not silently downgrade
acceptance criteria.

## Test levels

Choose the strongest available level and report the level actually reached:

1. **Environment discovery:** real Neovim binary and required tools; record
   versions.
2. **Shell syntax:** `bash -n install.sh` and
   `bash -n scripts/test-nvim-headless.sh` separately.
3. **Static checks:** Lua syntax, changed paths, generated files, installer
   behavior. Do not claim runtime coverage.
4. **Isolated installer checks:** temporary HOME/XDG; dry-run leaves files
   untouched, existing configs are backed up, Neovim-only mode leaves Emacs
   alone, virtualenvs are excluded.
5. **Mocked harness:** only orchestration or installer logic when a real
   dependency is unavailable. Label it mocked; it does not prove Neovim started.
6. **Plugin restore with real Neovim:** use the documented restore/sync command
   against `lazy-lock.json`. Do not silently upgrade. Record network, build, and
   dependency failures separately from configuration failures.
7. **Real headless startup:** launch the installed configuration and fail on
   Lua/plugin startup errors.
8. **Behavioral assertions:** assert the specific plugin or behavior directly.
   Checking that lazy.nvim loaded is insufficient.
9. **Interactive macOS check:** terminal rendering, font, clipboard, keymaps, LSP
   attachment, completion, and perceived latency.

A successful plugin download does not prove plugin configuration works; a
successful startup does not prove every lazy-loaded plugin or user workflow
works.

## Real LuaLS and Lazydev integration tests

Configuration inspection does not prove LuaLS can resolve plugin types or return
useful completions. For Lazydev, LuaLS workspace libraries, or Lua completion:

1. Install a pinned LuaLS release in CI and verify its published SHA-256.
2. Launch the actual configuration in a fresh headless process, open a named Lua
   buffer under a temporary workspace root, and wait for the real `lua_ls` client
   to attach.
3. Send `textDocument/completion` requests at representative plugin and Neovim
   API expressions. Assert concrete labels such as `telescope.builtin.find_files`
   and `vim.api.nvim_create_autocmd`; checking `package.loaded`, Lazydev's library
   table, or cmp source registration is not enough.
4. Replace the incomplete prefix with valid Lua, request hover on a resolved
   symbol, then allow diagnostics to settle and assert the buffer is clean. Do
   not rely only on `DiagnosticChanged`; servers may not emit it for an
   already-clean buffer.
5. Include `tests/nvim/**` in workflow path filters.

A LuaLS CLI `--check` run is diagnostic, not a substitute: it does not prove
Neovim loaded Lazydev, updated the workspace, or returned the completion.

## Lazy-loading behavior tests

A plugin spec can have multiple triggers; every trigger is an independent load
path. Test both the unwanted and intended paths.

For a filetype-driven plugin such as `go.nvim`:

1. Start fresh with an unrelated empty buffer and confirm the setup module is not
   loaded.
2. Dispatch an unrelated event that previously triggered the plugin (for example
   `CmdlineEnter`) and assert it remains unloaded.
3. Set each supported filetype in a separate fresh process (`go`, `gomod`) and
   assert the setup module loads.
4. Assert a user-visible integration point, such as `:GoBuild`, not only a
   package flag.
5. Keep plugin restoration and lockfile revisions unchanged unless the issue
   requires them.

Use `vim.api.nvim_exec_autocmds()` to exercise lazy.nvim's handlers. A direct
`require()` does not prove the trigger works. Use fresh processes for positive
filetype cases.

For Insert-mode integrations, verify that browsing leaves the plugin unloaded and
the first Insert-mode entry activates it. If activation downloads or starts an
external service, separate the deterministic lazy-load assertion from the
network/bootstrap check.

## CI must exercise the real configuration

- Prefer separate processes for dependency installation and normal startup.
- If a flag such as `DOTFILES_CI` is necessary, document exactly what it changes
  and ensure it is unset for normal startup.
- Do not rewrite plugin specs or silently remove `config`, `opts`, `init`,
  `build`, events, commands, filetypes, or key triggers to make installation
  pass.
- Do not skip native builds or plugin setup without naming the skipped work and
  covering it in a later test.
- Any test-only branch must be narrow, explicit, and covered by a separate
  normal-mode startup test.
- Keep failure logs and artifacts available.
- A run that only downloads plugin repositories does not prove initialization.

## Plugin and LSP ownership

- Keep plugin declarations readable and explicit. lazy.nvim accepts both
  individual and valid list-style specs.
- Tie lazy loading to actual use: filetype for language tooling, commands/keys
  for search/debug/test, Insert mode for typing assistants.
- Avoid overlapping providers for scrolling, formatting, linting, highlighting,
  and LSP setup.
- Assign one diagnostic producer per tool/filetype. In JavaScript/TypeScript, do
  not run the same ESLint config through both the ESLint language server and
  nvim-lint; competing asynchronous publishers can leave duplicate or stale
  diagnostics. Keep the ESLint LSP as owner when attached, with its save fix.
- Keep one canonical formatting path per filetype. When Conform owns `:Format`,
  avoid competing `vim.lsp.buf.format()` mappings that use a different formatter.
  Prettier follows Prettier config; it does not imply ESLint `--fix` ran.
- For a primary shortcut that must exist immediately and be tested, prefer a
  direct `vim.keymap.set()` with `desc` over queuing through legacy WhichKey
  `register()`. WhichKey v3 processes queued specs during setup, so an early
  headless `maparg()` assertion can be a false negative.
- Keep Lua development tooling filetype-lazy: lazydev as a separate root spec
  with `ft = "lua"`, not a dependency of an eagerly loaded LSP plugin. Enable its
  native LSP and nvim-cmp integrations deliberately. Translate Neodev's explicit
  plugin type list into lazydev `library` entries.
- Preserve `lazy-lock.json` unless a ticket explicitly includes a version change.
- Pin or document APIs when upstream plugins make breaking branch migrations.
- Verify optional executables before invoking external linters or formatters.
- Make missing tools produce actionable messages rather than repeated noise.

## Startup side effects and deferred integrations

- Keep optional external integrations lazy until the user performs the action
  that needs them. In this repo, Codeium's language server must not download or
  start because Neovim entered an empty buffer; defer it to `InsertEnter` and
  explicitly start its server from the plugin config.
- If a lazy plugin's own autocmd registers only after the triggering event, do
  not assume it will run retroactively. Invoke the intended entry point from the
  plugin config when required.
- Distinguish plugin restoration from runtime activation. A successful locked
  restore does not prove optional services can initialize.
- Remove stale integration calls only after verifying no spec or mapping
  provides them.

## Completion criteria

A fix is complete only when:

- Its acceptance criteria pass, or the remaining blocker is explicitly recorded.
- The diff has been reviewed against the intended behavior and surrounding code.
- Relevant automated checks pass, or the reason they cannot run is documented.
- The exact validation level and environment are reported honestly.
- The README/backlog is updated when behavior or setup instructions change.
- The user is told what changed, what was tested, and what remains unverified.

## References

- Test construction:
  [`.agents/skills/neovim-headless-testing/SKILL.md`](../neovim-headless-testing/SKILL.md)
- Runtime fingerprints:
  [`docs/incidents/neovim-runtime-fingerprints.md`](../../../docs/incidents/neovim-runtime-fingerprints.md)
- CI fingerprints:
  [`docs/incidents/ci-failure-fingerprints.md`](../../../docs/incidents/ci-failure-fingerprints.md)
