---
name: neovim-headless-testing
description: Write deterministic Neovim behavioral tests with pinned versions, isolated fixtures, real event dispatch, and observable assertions.
---

# Neovim headless testing

## Goal

Prove the behavior the maintainer would exercise, not merely that Neovim
started. Use a real headless process, the actual configuration, and the real
plugin/LSP/tool trigger. Report the level actually reached.

## Environment parity

- Use the Neovim version pinned by CI and the committed `lazy-lock.json`.
- Local plugin checkouts can drift. A local Neovim 0.12.6 with a newer
  nvim-treesitter could not compute TypeScript indent while the pinned 0.11.3
  environment could. When local and CI disagree, check versions before changing
  the product.
- Restore locked plugins; do not silently upgrade them.
- Keep test-only environment flags unset for the normal-startup phase.

## Test shape

- Prefer one Lua test file invoked with a single `+luafile` command.
- Use a fresh process for each case that must prove an independent lazy trigger;
  a plugin loaded once cannot demonstrate a second trigger.
- Print a concise `PASS:` line per assertion group so the phase log explains what
  ran.
- Exit nonzero on the first failed assertion and preserve the error text.
- Do not exceed Neovim's CLI option limit by passing one `+` option per
  assertion. Group related Lua or use `+luafile`.
- Keep the test deterministic: no arbitrary sleeps. Wait for a specific event,
  client attachment, command registration, or result table.

## Fixture isolation

Before asserting line or editing behavior, reset every option that can move the
line, and assert the reset:

```lua
vim.wo.foldenable = false
vim.wo.foldmethod = "manual"
vim.bo.autoindent = false
vim.bo.smartindent = false
vim.bo.expandtab = false
assert(vim.fn.foldclosed(line) == -1)
```

Inherited `foldmethod=syntax` with folds enabled made a native `o` open at the
fold boundary instead of the expected row. That was a fixture bug, not a product
regression. If fold behavior itself is under test, keep folds enabled and assert
the boundary explicitly.

Also pin the filetype and, when relevant, the buffer path. Use a temporary
workspace for LSP and Treesitter tests.

## Editing and mapping assertions

- `:normal` / `:normal!` does not run the full open-line path and skips
  `indentexpr` for the new line. Use `nvim_feedkeys(keys, "n", false)` inside a
  mapping to replay native keys without recursion. To exercise a user mapping
  from a test, use the default remapping mode (`nvim_feedkeys(keys, "m", false)`
  or omit the mode) so the mapping actually runs.
- Assert the final buffer text, cursor position, mode, and register state, not
  only that a mapping exists.
- Test counts (`2S`, `3o`) and cancellation paths when the mapping accepts them.
- Verify that a real closed fold still follows native behavior if the mapping
  special-cases folds.

## Lazy-loading assertions

- Start from an unrelated empty buffer and assert the target module is not
  loaded.
- Dispatch the real event with `vim.api.nvim_exec_autocmds()`; do not `require()`
  the plugin and call it proof that lazy loading works.
- Assert a user-visible integration point after loading, such as a command
  (`:GoBuild`, `:DapInstall`) or an attached client, not only a package flag.
- Test each positive filetype in its own process.
- For Insert-mode integrations, separate the deterministic lazy-load assertion
  from any network or external-service bootstrap.

## LSP and Treesitter assertions

- Wait for the real client to attach; assert the client name and root.
- Send `textDocument/completion` and assert concrete expected labels.
- Request hover on a resolved symbol to prove the server processed the buffer.
- Assert diagnostics after settling; do not rely only on `DiagnosticChanged`,
  because a server may not emit it for an already-clean buffer.
- A LuaLS `--check` run is diagnostic, not a substitute for the Neovim client
  test.

## Logs and artifacts

- Stream output live in CI and retain per-phase logs.
- Upload only phase logs and relevant XDG state logs; exclude plugin checkouts,
  caches, Mason packages, and downloaded binaries.
- Record the exact head SHA, Neovim version, lockfile revision, and run ID in the
  handoff.
- Distinguish a harness failure (before Neovim executes) from a configuration or
  behavior failure.

## Completion

A behavioral test is complete when it fails for the right reason before the fix,
passes after it, runs in CI on the relevant paths, and does not depend on
undocumented local state. If a behavior cannot be automated, document exact
manual steps and say why.
