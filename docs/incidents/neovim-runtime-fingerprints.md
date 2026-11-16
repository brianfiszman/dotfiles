# Neovim runtime fingerprints

Historical, repository-specific observations about runtime and plugin behavior.
Verify against the current configuration and locked revisions before reusing a
conclusion.

## Codeium must stay out of startup

Codeium's language server must not download or start merely because Neovim
enters an empty buffer. It is deferred to `InsertEnter` and explicitly started
from the lazy-plugin config at that event, because its own `BufEnter` autocmd is
registered after the first buffer-enter event. Issue
[#69](https://github.com/brianfiszman/dotfiles/issues/69).

When diagnosing startup, distinguish plugin restoration from runtime activation.
A successful locked restore does not prove that optional services can
initialize.

## Stale `repeat#set`

`core/general.lua` called `repeat#set` with no matching repeat mapping or plugin
provider. The call was removed rather than adding an unrelated plugin. Remove
stale integration calls only after verifying that no corresponding spec or
mapping exists.

## Neorg parser discovery

Both rocks could build and still be undiscoverable. The `lazy-rocks/<rock>/lib/lua/5.1`
directories were missing from Neovim's runtimepath. PR #71 declares both parser
repositories as Neorg dependencies, prepends their runtime directories before
`neorg.setup()`, and asserts each parser is discoverable and loadable.

## Mason install tests: use terminal events

Do not poll `Package:is_installed()` inside `vim.wait()`. Mason's implementation
scans the shared install root synchronously, so polling is expensive and is not
a reliable async completion signal. Subscribe to the registry-level
`package:install:success` and `package:install:failed` events and wait on an
in-memory result table.

Do not listen for a registry-level `package:handle` event: Mason does not emit
that event. The actual handle event is `package:install:handle`, whose single
argument is an `InstallHandle` with a `.package` field. The terminal events
`package:install:success` and `package:install:failed` receive
`(Package, receipt_or_error)` and fire after the handle is closed. Subscribe
before triggering installation, then wait on an in-memory result table; use a
one-time `is_installed()` scan only to account for packages already installed
before the observer attached. Never poll `is_installed()` inside `vim.wait()`.
The event-driven adapter test passed in run
[#43525656228](https://github.com/brianfiszman/dotfiles/actions/runs/43525656228).

## Mason DAP command entry points

`mason-nvim-dap.setup()` registers `:DapInstall` and `:DapUninstall` from its
command module. When the plugin is lazy, those commands must be in the parent
spec's `cmd` triggers, or the user cannot invoke either command to load it.

Lazy replays a command trigger immediately after `config()` returns, so the
commands must be available synchronously. For first-use registry data, use
Mason's no-callback `registry.refresh()` form, which completes before setup and
command replay. Keep adapter package installation asynchronous through Mason's
normal ensure-installed flow.

Regression coverage should assert both commands exist as lazy placeholders while
DAP modules are unloaded, invoke `:DapInstall` with no arguments in a fresh
process (an empty adapter list is a no-op), then assert both commands are
registered after activation.

## Headless test construction

Neovim limits the number of `+{command}` / `-c` options per invocation. Group
related assertions into one `+lua` or a `+luafile`; use separate fresh processes
only for independent lazy-load cases. Print a concise `PASS:` marker per
assertion group so phase logs explain what ran.

See also:
- [`ci-failure-fingerprints.md`](ci-failure-fingerprints.md)
- [`.agents/skills/neovim-headless-testing/SKILL.md`](../../.agents/skills/neovim-headless-testing/SKILL.md)


## Mason Tool Installer and Lazy startup ordering

The Mason Tool Installer plugin's internal `VimEnter` hook is unsafe when the
plugin is a Lazy dependency that is itself loaded during the `VimEnter` event.
The plugin script can register and execute that hook before Lazy calls the
plugin's `config()`; `run_on_start()` then sees the default empty
`ensure_installed` table and returns without provisioning the configured CLI.
Symptoms: startup waits for `dotfiles_treesitter_ready`, but no
`tree-sitter-cli` package appears in `mason.log`.

Set `run_on_start = false`, call `mason-tool-installer.setup(opts)`, and
schedule `check_install(false)` after setup. The Treesitter config must
register its `MasonToolsUpdateCompleted` listener before the scheduled check
runs. This makes the first CLI install deterministic even when Lazy loads the
dependency during `VimEnter`.

A cold-install integration test must allow the complete first-run parser
provisioning window, not a warm-start deadline. Use the test's 20-minute parser
install timeout and a 30-minute startup phase deadline within the 60-minute
workflow job.


## Mason Tool Installer must not eagerly activate Mason DAP

The Mason Tool Installer's default `integrations.mason-nvim-dap = true`
requires `mason-nvim-dap.mappings.source` during setup. Under Lazy module
autoload, that module belongs to the `mason-nvim-dap.nvim` plugin, so requiring
it loads the DAP plugin and its dependencies even when no debug action was
requested. This violates the repository's lazy-DAP contract and makes the
Neotest idle-startup test fail before its first test action.

When Mason Tool Installer is used only for unrelated packages such as
`tree-sitter-cli`, disable just that bridge:
`integrations = { ["mason-nvim-dap"] = false }`. Mason DAP remains independently
configured and lazy; its adapter install list is owned by
`dap.mason-nvim-dap.lua`. Keep the idle-startup assertion in
`tests/nvim/neotest-lazy-loading.lua` and verify explicit DAP command triggers
separately.
