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

Do not listen for a registry-level `package:handle` event. The install handle is
exposed by each `Package` instance, not emitted as a registry lifecycle event; a
registry listener for it never fires. Incident: a test timed out despite Mason
completing installs. Replacing the listener with terminal events passed the five
adapter installations in run
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
