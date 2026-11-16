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

- Use the latest stable Neovim release pinned by CI and the committed
  `lazy-lock.json`. Do not add older stable versions to the matrix solely for
  backward compatibility; only add them when the maintainer explicitly asks.
- Keep plugin branches and lockfile revisions aligned with the current upstream
  APIs under test. Restore locked plugins; do not silently upgrade them during
  a test.
- When local and CI disagree, compare Neovim, plugin SHA, parser revisions,
  installed external tools, and XDG paths before changing product code.
- Keep test-only environment flags unset for the normal-startup phase.

## Local-versus-CI dependency diagnosis

A green CI run is not proof that the maintainer's Mac has the tested plugin
checkout or patch. When local behavior differs:

1. Record `nvim --version`, `:echo stdpath("config")`, and
   `:echo stdpath("data")` from the failing Neovim process.
2. Read the committed `lazy-lock.json` entry, then inspect the actual local
   plugin checkout with `git -C <plugin-dir> rev-parse HEAD`.
3. Check `git -C <plugin-dir> diff -- <relevant-file>` and verify the expected
   compatibility patch/function exists in the installed checkout.
4. Check the active Neovim PATH with `vim.fn.executable("<tool>")`; do not
   assume the interactive shell PATH is inherited.
5. For Treesitter, record parser ABI, installed parser path, and the relevant
   query/indent feature. A missing optional CLI does not mean the parser is
   missing.
6. Capture this state before `:Lazy update`, `:TSUpdate`, reinstall, or
   manual edits. Those actions can erase the original mismatch.

The lockfile describes the intended revision; it is not an inventory of local
installed files. A clean-install CI pass validates its exact branch/head and
isolated XDG environment only. Follow
`.agents/skills/neovim-dependency-management/SKILL.md` for package/provider
classification and safe installation paths.

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

## Self-diagnosing tests for remote-only agents

Some agents, including Codex, cannot run Neovim locally. The CI log is then the
only debugging surface, so each run must explain itself.

- Print the environment once: `vim.version()`, filetype, relevant options,
  `foldclosed(line)`, and the lockfile revision when it matters.
- Assert expected vs actual in the failure message, not only at the end of the
  file.
- Use a small helper so every failure carries context:

```lua
local function check(label, expected, actual)
  if not vim.deep_equal(expected, actual) then
    error(("%s: expected %s, got %s"):format(
      label,
      vim.inspect(expected),
      vim.inspect(actual)
    ))
  end
  print("PASS: " .. label)
end
```

- Wrap external calls in `pcall` and include the error text in the failure.
- One run should answer one hypothesis and all its sub-questions. Do not push
  one assertion per run.
- Do not add a probe notebook. Keep diagnostics as assertions in the test file
  and remove temporary prints before review.

- Wrap the test entrypoint in `xpcall()`; on an uncaught assertion or runtime
  error, print the traceback and terminate Neovim with a non-zero exit (for
  example, `:cquit 1`). Do not let an exception skip the final `:qa!` and
  leave a headless process alive until the workflow timeout.
- In platform-specific shell runners, stream Neovim output through `tee` while
  preserving the Neovim and log-writer exit statuses. File-only capture hides
  the last successful assertion when a process hangs or is cancelled.

## Asynchronous errors and unrelated integrations

A headless Neovim process can exit with status 0 after an exception in a
scheduled callback. The runner must treat visible asynchronous callback errors
such as `vim.schedule callback` and `Invalid buffer id:` as test failures;
do not rely only on Neovim's exit status or synchronous Lua error patterns.

Keep each behavioral test's scope narrow. When a test repeatedly creates and
deletes temporary buffers to verify editing or indentation, disable unrelated
LSP auto-activation in that disposable process with
`vim.lsp.enable(configured_servers, false)` and assert that no clients remain.
Plugins such as Lspsaga can schedule document-symbol requests after buffer
changes; those callbacks may outlive a temporary buffer and produce misleading
failures in a test that does not exercise LSP. Do not apply this isolation to
tests whose purpose is to verify LSP attachment, requests, completion, or
diagnostics, and do not globally suppress the resulting callback errors.

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

When a test invokes `nvim_input()`, do not immediately block in
`vim.wait()` in the same synchronous `+luafile` chunk and assume the editor
will consume queued typeahead. Either return to the main loop and assert from a
`vim.defer_fn()` callback, or use
`nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "mtx", false)`
to synchronously drain real typed keys while still honoring user mappings.
The `"m"` flag is important: `"n"` would bypass the mapping under test.

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

## Telescope lazy-loading tests

Test each Lazy path in a fresh process: an LHS-only `keys` stub (real key
dispatch), the `cmd` trigger with arguments, and a plugin mapping that
`require()`s Telescope. Audit indirect dependencies and `VeryLazy` configs for
eager imports. Keep integrations such as Scope active but defer their Telescope
extensions until first use. Call `telescope.setup()` before
`telescope.load_extension()`. Assert real picker results, not only module state;
check optional preview executables and report skipped interactions separately.

## Current nvim-treesitter integration

The current `nvim-treesitter/main` rewrite targets Neovim 0.12+ and requires
`tree-sitter-cli` 0.26.1+ plus a C compiler.

- Use the real Mason registry/package and assert that
  `vim.fn.exepath("tree-sitter")` resolves the installed executable.
- Parse and assert the CLI's actual version; do not mock its output.
- Exercise the real parser installation/update path and assert the expected
  parser libraries are discoverable through Neovim's runtimepath.
- Open real files for JavaScript, TypeScript, JSX, TSX, HTML, Lua, JSON and YAML;
  assert language mapping, parsing, active highlighting and configured
  `indentexpr`.
- Exercise editing mappings and standalone autotag behavior through real
  Neovim input, not direct helper function calls.
- Keep parser compilation in an isolated HOME/XDG environment. Never install
  tools or modify the maintainer's real Mac from CI.

## Preserve combined Vim and Treesitter highlighting

The legacy Treesitter highlight module could enable both Tree-sitter and Vim
regex syntax highlighting through `additional_vim_regex_highlighting`. In the
current Neovim API, `vim.treesitter.start()` marks the buffer with
`b:ts_highlight`; Neovim's normal FileType syntax hook then skips loading the
Vim syntax file. To preserve the combined behavior, set
`vim.bo[bufnr].syntax = "ON"` after `vim.treesitter.start()` succeeds and
test both `b:ts_highlight` and `b:current_syntax`.

Do not restrict buffer activation to the list passed to automatic parser
provisioning. The old modules attach to any installed parser with the relevant
queries. Resolve the filetype's language, confirm the parser is available, and
check its `highlights` / `indents` query groups independently. Add a test
that installs an extra parser outside the managed list and opens a matching
buffer; this catches regressions hidden by testing only ensured parsers.

When a behavioral fixture positions the cursor inside code, explicitly
establish the fold state first. The real config may enable `foldmethod=syntax`
and leave folds closed by default; Neovim can move a cursor set inside a closed
fold to its boundary, so a textobject test may select a different declaration
even though the query/mapping is correct. Disable folds for tests of textobject
semantics, and cover fold-boundary behavior in a separate focused test when
that behavior is under review.

## Mason Tool Installer optional integrations and Lazy

Disable an integration when its module should remain lazy. In particular,
`mason-tool-installer` enables `mason-nvim-dap` integration by default and
requires `mason-nvim-dap.mappings.source` during setup. With Lazy's module
autoload, that require can activate the entire `mason-nvim-dap.nvim` plugin and
its `nvim-dap` dependencies during ordinary startup. Set
`integrations = { ["mason-nvim-dap"] = false }` when the installer only needs
to provision unrelated packages such as `tree-sitter-cli`. This does not
disable Mason DAP itself: the dedicated DAP spec still loads it on explicit
debugger commands or mappings, and its own `ensure_installed` list remains the
source of debugger-adapter provisioning.

## Standalone nvim-treesitter-textobjects on main

The current textobjects plugin is configured independently of
`nvim-treesitter.configs`:

- Pin `nvim-treesitter/nvim-treesitter-textobjects` to `main`.
- Call `require("nvim-treesitter-textobjects").setup({...})`.
- Add mappings through `nvim-treesitter-textobjects.select` and
  `nvim-treesitter-textobjects.move`; keep filetype-specific mappings
  buffer-local when replacing a plugin's old integration.
- Test real parser-backed selections and cursor movement on fixture files.
- Do not reintroduce `nvim-treesitter.configs` or assume go.nvim's bundled
  textobjects hook supports the current API. Its latest code still treats that
  legacy hook as optional; disable it and configure the standalone plugin.

## Mason provisioning and lifecycle

Register terminal package-event listeners before scheduling Mason Tool Installer
`check_install(false)`; never poll `is_installed()` in `vim.wait()`. Keep initial
CLI/parser provisioning out of restore-only `:Lazy! restore` with
`DOTFILES_SKIP_TREESITTER_PROVISIONING=1`; normal startup runs without it and
waits for parser readiness. Event details:
`docs/incidents/neovim-runtime-fingerprints.md`.

## LSP and Treesitter assertions

- Wait for the real client to attach; assert the client name and root.
- Send `textDocument/completion` and assert concrete expected labels.
- Request hover on a resolved symbol to prove the server processed the buffer.
- Assert diagnostics after settling; do not rely only on `DiagnosticChanged`,
  because a server may not emit it for an already-clean buffer.
- A LuaLS `--check` run is diagnostic, not a substitute for the Neovim client
  test.

## Existing plugin checkout regressions

When a startup patch is added to an existing lazy.nvim plugin spec, test more
than the clean-install build hook. In the isolated workspace:

1. Restore the locked plugin and verify the install/update build hook applies
   the patch.
2. Reverse the patch in that disposable checkout while keeping its Git revision
   fixed.
3. Start Neovim through the normal config path and verify the startup `init`
   hook reapplies the patch before plugin modules load.
4. Verify exact plugin SHA, patch presence, and the relevant user-visible
   behavior after startup.

This catches the case where CI's fresh install works but a maintainer's existing
plugin directory never ran the newly-added build function. Do not reverse or
patch a maintainer's real plugin checkout as part of CI.

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
