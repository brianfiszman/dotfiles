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
For comparing or selecting third-party dependencies, follow `.agents/skills/dependency-research/SKILL.md`.

## Plugin selection and replacement review

This review is mandatory before adding, removing, replacing, upgrading, or materially
reconfiguring a plugin. Scale its depth to the change, but do not skip it.

1. Define the exact user-visible role and behavior in use. Do not conflate inline
   AI completion, popup completion, LSP features, chat, and agent workflows.
2. Inspect the exact upstream project and service: archive/maintenance status,
   recent meaningful commits/releases, unresolved regressions, supported Neovim
   and API versions, license, authentication, and service availability.
3. Compare the current choice, maintained alternatives, native Neovim/LSP
   capabilities, existing components, and removing the dependency.
4. Evaluate behavior/quality, latency and startup cost, runtime/download/build
   burden, privacy and data routing, API/service cost, portability, license,
   migration/rollback effort, and long-term maintenance risk.
5. Record keep/replace/remove/defer with evidence, links, trade-offs, and unknowns
   before changing the plugin spec or lockfile. Do not decide on star count alone
   or bulk-upgrade unrelated dependencies.

For external AI backends, prove authentication and real completion responses
before treating startup or keymaps as validated. A lazy-loading change cannot
repair an archived client or unavailable service.

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

Testing belongs to every issue's scope and estimate. Before implementation,
define observable success, failure/edge, and non-regression scenarios; name the
unit, integration, or end-to-end proof. For editor behavior, use a real headless
Neovim process with the actual config/plugins/LSP/tools, trigger the user path,
and assert its result. Mocks, syntax checks, startup success, and module-loaded
flags do not prove interactive behavior. Run focused and regression checks in CI
with explicit path triggers; isolate HOME/XDG. Manual Mac checks supplement
automation only where it is impractical.


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

Choose the strongest available level and report it explicitly: environment and
version discovery; shell/static checks; isolated installer checks; mocked
harnesses (clearly labeled); real locked-plugin restore; normal headless startup;
direct behavioral assertions; and interactive macOS checks. A successful plugin
download does not prove setup, and startup does not prove lazy workflows. Never
silently downgrade required acceptance criteria.


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

- Keep AI completion providers lazy until the user begins typing, but verify
  that the selected client and backend are still supported and return real
  suggestions before tuning lazy-loading triggers.
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
