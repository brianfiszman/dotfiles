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

## Review every change as code

Before accepting a patch or reporting a change complete:

- Read the full diff, not just the PR title, issue, commit message, or summary.
- Inspect surrounding code to understand the control flow and the configuration
  that remains active outside the changed lines.
- Look for accidental comments, literal escape sequences (for example, a
  visible `\\n` where a line break or separate comment was intended), malformed
  Lua tables, overwritten options, duplicate setup calls, and stale names.
- Check that environment-specific branches do not silently change normal
  interactive behavior.
- Verify that test-only conditions are scoped and reset deliberately; do not
  leave a CI environment variable active for the normal-startup phase.
- Compare the final files with the relevant issue's acceptance criteria. A
  change being unique to a branch does not make it correct or necessary.

When reviewing a multi-file change, inspect each modified file's actual patch
and identify any behavior that could change outside the stated scope.

## Issue quality

Create one issue for each independently testable behavior. A good issue contains:

1. **What you notice** — describe the current behavior in plain language.
2. **Desired behavior** — describe what should happen from the user's perspective.
3. **Scope** — list the configuration area or files likely involved.
4. **Acceptance criteria** — concrete checks that prove the behavior changed.
5. **Validation** — say whether the check is static, targeted headless, full
   integration, or requires manual interaction.

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

## Mandatory behavior-first testing

Testing is part of every issue's scope and estimate. Do not defer it to a later cleanup task or mark an implementation complete before its required tests pass.

When creating or refining an issue:
1. Define observable scenarios before implementation: the normal user path, relevant failure/edge paths, and behavior that must not regress.
2. Name the automated proof required. Use unit tests for isolated logic, integration tests for real boundaries, and end-to-end tests when a complete workflow crosses multiple components.
3. For editor behavior, automate the local usage path with a real headless Neovim process and the actual configuration/plugins/LSP/tools wherever practical. Trigger the same event, mapping, command, completion request, or workflow the maintainer would use, then assert its observable result.
4. Do not treat syntax checks, mocks, package-loaded flags, command registration, or successful startup as proof that an interactive feature works. These may be useful lower-level checks, not substitutes for behavior coverage.
5. Include focused tests and the relevant broader regression suite in CI with explicit PR/path triggers. If a test is moved to a scheduled/manual workflow, preserve equivalent coverage and document the trigger.
6. Isolate HOME/XDG and generated state. Manual Mac verification supplements automation; document exact steps and rationale only where a behavior cannot reasonably be automated.

A task's Definition of Done requires implementation, passing automated behavioral tests on the exact change, passing required CI checks, and an honest report of anything still unverified. Pure documentation-only edits may use Markdown/diff review when they do not change behavior.

## Select tests by change impact

Use the smallest test set that gives meaningful evidence, then expand it when
the change can affect more of the startup or installation path. Do not run the
full plugin restore for every comment or documentation edit, but do not use a
quick check to sign off a high-impact change.

| Change type | Minimum useful validation |
|---|---|
| Documentation-only | Markdown/diff review; no Neovim run required |
| Shell script or installer | `bash -n`, isolated dry-run, and focused install/backup tests |
| Lua-only logic or keymap | Lua syntax and targeted headless check when the environment permits |
| Plugin spec, lazy loading, LSP, Treesitter, startup | Real Neovim headless startup; add plugin restore when dependencies or lockfile are involved |
| Bootstrap, installer flow, XDG paths, CI harness | Full isolated integration: install, restore locked plugins, then normal headless startup |
| Performance optimization | Repeatable before/after measurement under the same conditions, plus behavior regression checks |

When a required dependency is unavailable, run the strongest useful lower-level
checks and state exactly what remains unverified. Do not silently downgrade the
acceptance criteria.

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
6. **Plugin restore with real Neovim:** use the repository's documented restore
   or sync command against the versions in `lazy-lock.json`. Do not silently
   upgrade plugins. Record network, build, or dependency failures separately
   from configuration failures.
7. **Real headless startup:** launch the installed configuration again with a
   real Neovim binary and fail on Lua/plugin startup errors. A script named
   "headless test" or a mocked `nvim` executable does not by itself establish
   that this level passed.
8. **Behavioral assertions:** when an issue concerns a specific plugin or
   behavior, assert that behavior directly. Check that critical lazy-loaded
   plugins can load through their real trigger or a deliberate test command;
   checking only that lazy.nvim itself loaded is insufficient.
9. **Interactive macOS check:** validate terminal rendering, font, clipboard,
   keymaps, LSP attachment, completion, and perceived typing latency on the
   maintainer's Mac.

The automated test is intended to prove that a clean checkout can install and
start in an isolated environment. Confirm what the current script really
executes before describing its coverage. A successful plugin download does not
prove plugin configuration works; a successful startup does not prove every
lazy-loaded plugin or user workflow works.

## Real LuaLS and Lazydev integration tests

Configuration inspection is necessary but does not prove that LuaLS can resolve a
plugin's type definitions or return useful completions. For changes to Lazydev,
LuaLS workspace libraries, or Lua completion:

1. Install a pinned LuaLS release in CI and verify its published SHA-256 before
   execution. Do not silently depend on whatever server version happens to be
   available on the runner.
2. Launch the actual Neovim configuration in a fresh headless process, open a
   named Lua buffer under a temporary workspace root, and wait for the real
   `lua_ls` client to attach.
3. Send `textDocument/completion` requests through that client at representative
   plugin and Neovim API expressions. Assert concrete expected labels such as
   `telescope.builtin.find_files` and `vim.api.nvim_create_autocmd`; checking
   only `package.loaded`, Lazydev's library table, or nvim-cmp source
   registration is not enough.
4. Replace the deliberately incomplete completion prefix with valid Lua,
   request hover on a resolved symbol to establish that LuaLS processed the
   change, then allow diagnostics to settle and assert that the buffer is clean.
   Do not rely solely on a `DiagnosticChanged` event: servers may not emit a
   diagnostics notification when the buffer was already clean.
5. Ensure workflow path filters include `tests/nvim/**`, so edits to behavioral
   tests actually run CI.

A LuaLS CLI `--check` run can be useful for diagnosing a workspace, but it is
not a substitute for this integration test: it does not prove that Neovim
loaded Lazydev, updated the active LSP workspace, or returned the expected
completion response.

## Lazy-loading behavior tests

A plugin spec can have multiple triggers. Every trigger is an independent way to
load the plugin, so test both the unwanted path and the intended path.

For a filetype-driven plugin such as `go.nvim`:

1. Start a fresh Neovim process with the real configuration and confirm the
   plugin's setup module is not loaded during an unrelated empty-buffer startup.
2. Dispatch an unrelated event that previously triggered the plugin (for
   example, `CmdlineEnter`) and assert that it remains unloaded.
3. Set the buffer filetype to each supported value in separate fresh processes
   (for example, `go` and `gomod`). Assert that the plugin setup module loads.
4. Assert one user-visible integration point after loading, such as the
   expected user command (`:GoBuild`), rather than only checking a package
   flag.
5. Keep plugin restoration and lockfile revisions unchanged unless the issue
   explicitly requires them.

Use Neovim's real event dispatch, such as
`vim.api.nvim_exec_autocmds()`, to exercise lazy.nvim's registered handlers.
A direct `require()` of the plugin module does not prove that the lazy trigger
works. Use a fresh process for each positive filetype case because a plugin
loaded once cannot demonstrate a second independent trigger.

For Insert-mode integrations, verify that browsing a buffer leaves the plugin
unloaded and that the first Insert-mode entry activates the plugin. If activation
downloads or starts an external service, separate the deterministic lazy-load
assertion from the network/bootstrap check; do not make CI silently skip the
normal plugin configuration or claim that the external service was tested.

### Headless test command limits and diagnostic output

Neovim limits how many `+{command}` / `-c {command}` options a single
invocation accepts. A behavioral test that adds one CLI option per assertion can
fail before Neovim starts with `Too many "+command" ... arguments`. That is a
test-harness construction failure, not an application regression.

- Group related assertions and state transitions into one `+lua` command, or
  move them into a dedicated Lua test file invoked with one `+luafile` command.
- Keep independent lazy-loading cases in fresh Neovim processes when a plugin
  can only be loaded once per process.
- Print a concise `PASS:` line after each meaningful assertion group so the
  per-phase log artifact explains what was actually verified.
- When a harness run fails before the editor executes, read the exact error and
  fix the harness; do not weaken the behavioral assertions.

Incident 2026-11-13: the first Go lazy-loading probe exceeded Neovim's command
limit because it passed each assertion as a separate `+` option. Grouping the
Lua statements into one option per scenario fixed the harness. The final exact
head and successful run are recorded in
[the validation skill](./github-actions-validation/SKILL.md).

## CI must exercise the real configuration

CI may use a dedicated installation phase, but it must not make the tested
configuration materially different from the one the maintainer runs.

- Prefer separate processes for dependency installation and normal startup.
- If a flag such as `DOTFILES_CI` is necessary, document exactly what it changes
  and ensure it is unset for the normal-startup test.
- Do not broadly rewrite plugin specs or silently remove `config`, `opts`,
  `init`, `build`, events, commands, filetypes, or key triggers just to make
  the installation phase pass.
- Do not skip native builds or plugin setup without naming the skipped work and
  adding a later test that covers it when it affects normal use.
- Any test-only branch must be narrow, explicit, and covered by a separate
  normal-mode startup test.
- Keep failure logs and artifacts available so CI failures can be diagnosed.
- A CI run that merely downloads plugin repositories must not be described as
  proving successful plugin initialization.

Clearly distinguish an expected CI check, a missing CI run, a failed CI run,
and a passing CI run.

## Setup, CI, and documentation changes

- Improve the setup and test infrastructure when that is the right way to close
  a reproducibility or safety gap.
- Keep CI focused on deterministic checks; do not hide failures by weakening
  assertions or silently skipping unavailable steps.
- Update the README when installation commands, prerequisites, or user-facing
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
- Assign one diagnostic producer per tool/filetype. In JavaScript/TypeScript,
  do not run the same ESLint configuration concurrently through both the ESLint
  language server and nvim-lint (eslint / eslint_d): asynchronous results from
  competing publishers can leave duplicate or stale-looking diagnostics. Keep
  the ESLint LSP as the diagnostic owner when it is already attached and retain
  its save-time fix action.
- Keep one canonical formatting path per filetype. When Conform owns the
  user-facing :Format command, avoid attaching competing vim.lsp.buf.format()
  mappings that silently use a different formatter. Be precise about formatter
  semantics: Prettier follows Prettier configuration; it does not automatically
  mean that ESLint --fix rules were run.
- For a primary shortcut that must exist immediately and be behaviorally tested,
  prefer a direct vim.keymap.set() with desc over queuing it through legacy
  WhichKey register(). WhichKey v3 processes those queued specs during setup;
  an early headless maparg() assertion can therefore be a false negative before
  the deferred registration has completed.

- Keep Lua development tooling filetype-lazy: declare lazydev as a separate
  root plugin spec with `ft = "lua"`, not as a dependency of an eagerly loaded
  LSP plugin. Enable its native LSP and nvim-cmp integrations deliberately.
  Translate Neodev's explicit plugin type list into lazydev's `library` entries
  when those APIs must remain available even before a module is required.
- Preserve `lazy-lock.json` unless a ticket explicitly includes a plugin version
  change.
- Pin or document APIs when upstream plugins make breaking branch migrations.
- Verify optional executables before invoking external linters or formatters.
- Make missing tools produce actionable messages rather than repeated noise.

## Completion criteria

A fix is complete only when:

- Its acceptance criteria pass, or the remaining blocker is explicitly recorded.
- The diff has been reviewed against the intended behavior and surrounding code.
- Relevant automated checks pass, or the reason they cannot run is documented.
- The exact validation level and environment are reported honestly.
- The README/backlog is updated when behavior or setup instructions change.
- The user is told what changed, what was tested, and what remains unverified.


## Native plugin build dependencies and failure diagnosis

A plugin restore can fail before Neovim reaches normal startup. Diagnose the layer
before changing plugin configuration:

- Separate repository download, LuaRocks dependency resolution, native compilation,
  plugin configuration, and normal startup. They are different failure stages.
- Read the exact build log and identify the missing executable, interpreter, header,
  compiler, or library. Do not infer a missing dependency from the plugin name alone.
- Keep CI system prerequisites in the workflow. The dotfiles installer must remain
  free of OS package-manager operations.
- Preserve `lazy-lock.json`, plugin build hooks, and the normal configuration while
  fixing missing CI prerequisites. Do not disable native builds or weaken the
  plugin spec to get a green run.
- Treat a dependency-install change as a hypothesis until a fresh restore and a
  separate normal headless startup both complete successfully.

### Resolved Neorg restore and parser-discovery incidents — 2026-11-13

The original Neorg restore failure was caused by the Hererocks environment
lacking Lua 5.1. The CI workflow now installs `lua5.1` and
`liblua5.1-0-dev` while preserving the real plugin setting
`rocks = { hererocks = true }`. Do not disable Hererocks or skip native parser
builds to get a green CI run.

A second problem remained after both rocks built: Neorg could not discover the
parser shared libraries because their `lazy-rocks/<rock>/lib/lua/5.1`
directories were missing from Neovim's runtimepath. PR #71 now declares both
parser repositories as Neorg dependencies, prepends their runtime directories
before `neorg.setup()`, and asserts that each parser is discoverable and
loadable.

Full clean integration passed in [run 43495833655](https://github.com/brianfiszman/dotfiles/actions/runs/43495833655)
for exact head `98479d39470e82609402ca30e7f3e363978022b1`: isolated preparation,
locked plugin restore/build hooks, normal headless startup, and both parser
assertions. The final trace contained no Neorg missing-parser warning. Later
commits require their own current-head validation; this incident is resolved
for the validated snapshot, not by assumption for all future revisions.


## Startup side effects and deferred integrations

- Keep optional external integrations lazy until the user performs the action that needs them. In this repo, Codeium's language server must not download/start merely because Neovim enters an empty buffer; defer the plugin to `InsertEnter` and explicitly start its server from the lazy-plugin config at that event.
- If a lazy plugin's own autocmd is registered only after the event that triggered lazy loading, do not assume that autocmd will run retroactively. Invoke the intended entry point explicitly from the plugin config when that is required.
- When diagnosing a clean headless startup, distinguish plugin restoration from runtime activation. A successful locked restore does not prove that optional services or first-run language-server downloads can initialize.
- Remove stale integration calls only after verifying that no corresponding plugin/spec or mapping exists. Here, `repeat#set` had no configured provider or matching mapping and was removed rather than adding an unrelated plugin.



## Mason package-install regression tests

For Mason-managed adapters, observe terminal install lifecycle events instead of
polling `Package:is_installed()` inside a `vim.wait()` predicate:

- Subscribe to the registry-level `package:install:success` and
  `package:install:failed` events and keep terminal results in an in-memory
  table.
- Do not subscribe to a registry-level `package:handle` event: the install
  handle is exposed by each `Package` instance, not emitted as a registry
  lifecycle event. A registry listener for `package:handle` never fires.
- Wait on the terminal-result table. Avoid repeated `Package:is_installed()`
  calls during active installs: the current Mason implementation scans the
  shared install root synchronously, so polling is expensive and is not a
  reliable async completion signal.
- For an adapter that is already installed before the action, seed its result
  as existing/successful. In a clean isolated CI workspace, the remaining
  adapters must produce the registry success events after the actual command
  is invoked. If the test needs to prove that the command requested adapters,
  also assert the expected package request/installation path rather than
  treating a pre-existing installed package as evidence of a new request.
- Preserve stderr for failed handles in the test output and assert every
  expected adapter reaches a successful terminal state.

Incident 2026-11-13: a headless test listened for a nonexistent registry-level
`package:handle` event and timed out even though Mason completed installs.
Replacing that listener with `package:install:success` /
`package:install:failed` observers passed the five adapter installations in
[run #43525656228](https://github.com/brianfiszman/dotfiles/actions/runs/43525656228).
This validates the registry terminal-event signal; it does not establish that
every Mason install stall has the same root cause.

## Lazy entry points for Mason DAP commands

`mason-nvim-dap.setup()` registers `:DapInstall` and `:DapUninstall`
from its command module. When `mason-nvim-dap.nvim` is moved behind a lazy
parent spec, these commands need to be included in the parent's Lazy `cmd`
triggers as well; otherwise a user cannot invoke either command to cause the
parent plugin to load.

Regression coverage should assert both commands exist as lazy placeholders
while the DAP modules are still unloaded, then invoke `:DapInstall` with no
arguments in a fresh headless process. An empty adapter list is a no-op, so it
tests the real command entry point without opening Mason UI or changing installed
packages. After activation, assert both commands were registered by
`mason-nvim-dap`.


## Registry-dependent command entry points

Lazy replays a command trigger immediately after the plugin's `config()`
returns. Mason's `:DapInstall` and `:DapUninstall` commands are registered
by `mason-nvim-dap.setup()`, so a lazy command-triggered load must make those
commands available synchronously before returning from config.

When the first command may need registry data (for example
`:DapInstall python`), use Mason's no-callback `registry.refresh()` form,
which completes the refresh before setup and command replay. An asynchronous
refresh callback can register commands too late for Lazy's immediate replay.
Keep the expensive adapter package installations asynchronous through Mason's
normal ensure-installed flow. Test the Mason command trigger first in the
headless sequence, before any other DAP test populates the registry.

## Indentation ownership and mapping tests

- Native `autoindent` / `smartindent` and `filetype plugin indent on` remain
  configured in `core/general.lua`; filetype indent scripts can therefore be
  active even when Treesitter does not provide a query for a language.
- `treesitter.lua` enables the nvim-treesitter `indent` module. At the pinned
  plugin revision, the module attaches `nvim_treesitter#indent()` only when the
  parser language has an `indents` query. Verify the actual buffer-local
  `indentexpr` and installed parser instead of assuming all configured
  filetypes use Treesitter indentation.
- Lua has its own pinned `queries/lua/indents.scm`; TypeScript's pinned query
  inherits the ECMA indentation query. The indent-blankline and mini.indentscope
  plugins provide visual guides, not the indentation calculation.
- When a Normal-mode edit must use the active buffer indentation engine before
  replacing/opening a line, run the native `==` operator before the native
  `S`, `o`, or `O` action and preserve the user's count.
- In headless tests, `nvim_feedkeys(..., "x", ...)` sends an implicit Escape at
  end-of-typeahead if the editor remains in Insert mode. Avoid synchronous
  `feedkeys(..., "x!")` to assert an active Insert-mode transition: it can keep
  execution in the input loop until more input arrives. `nvim_input()` is
  non-blocking and accepts key notation such as `"<Esc>"`, but its input is
  processed only after the current Lua command yields to Neovim's main loop.
  Therefore, do not call `vim.wait()` from the same `+luafile` chunk and expect
  queued input to have run. Queue the user input, return from the Lua chunk,
  then use `vim.defer_fn()` callbacks to assert the resulting mode with a
  bounded deadline. Let the final callback exit Neovim with `qa!`; do not pass
  a subsequent command-line `+qa!` that can quit before the deferred test runs.
- Invoke behavioral Lua files directly with `+luafile` so an assertion failure
  is reported through the normal test process and log scanner. Print trace/pass
  markers before and after input transitions so a timeout identifies the last
  action reached instead of leaving an empty behavior log.

## Preserve functional files when rebuilding a PR tree

When creating a Git tree from the base branch to preserve a merge base, include
all existing branch-only functional files—not just the newest documentation or
test edits. After moving the ref, compare the PR head against the exact base and
verify that both implementation files and their test-runner wiring remain in the
diff. A green workflow is not evidence for a feature when its test is absent
from the executed script or its behavior log is missing from the artifact.
