# CI failure fingerprints

Historical, repository-specific observations. They are not universal rules; use
them to recognize a layer faster, then verify against the current workflow and
logs.

## Workflow parse: `runner` context at job level

The Neovim workflow set `NVIM_TEST_DIR: ${{ runner.temp }}/...` in the job-level
`env`. GitHub rejected the workflow before execution with
`Unrecognized named-value: 'runner'`. Moving the expression to the test step's
`env` fixed it. Run
[43475125584](https://github.com/brianfiszman/dotfiles/actions/runs/43475125584).

## Neorg / LuaRocks: missing Lua 5.1

The restore failed because the Hererocks environment lacked Lua 5.1. CI installs
`lua5.1` and `liblua5.1-0-dev` while preserving `rocks = { hererocks = true }`.
Do not disable Hererocks or skip native parser builds to get green CI.

## Neorg parser discovery

Installing the rocks was not enough: `lazy-rocks` parser directories were not on
Neovim's runtimepath. PR #71 declares `tree-sitter-norg` and
`tree-sitter-norg-meta` as dependencies, prepends their Lua 5.1 runtime
directories before `neorg.setup()`, and asserts both parsers are discoverable
and loadable.

## Go helper false green

Run [43490592093](https://github.com/brianfiszman/dotfiles/actions/runs/43490592093)
passed while logging `Vim:install golines failed:`. `go.nvim`'s bulk
`update_all_sync()` hook attempted optional binary installs, and the plugin
notification did not make Neovim exit nonzero. PR #71 removed the bulk hook from
default setup and makes the smoke test fail on that notification signature
during restore.

## Workspace preflight ran after initialization

Run [43481043006](https://github.com/brianfiszman/dotfiles/actions/runs/43481043006)
failed with `NVIM_TEST_DIR must be empty before the prepare phase`. The script
created `$HOME` and XDG directories before calling `prepare()`, so the emptiness
check could never pass. Fix commit
[10dfd2d](https://github.com/brianfiszman/dotfiles/commit/10dfd2d3969e9e6ffbdd03bbbc67668c4ad7f778):
move the preflight to top-level setup before any `mkdir`, and keep it limited to
`prepare`/`all`.

## Clean-start timeout in Codeium bootstrap

Run [43485726816](https://github.com/brianfiszman/dotfiles/actions/runs/43485726816)
passed preparation and restore, then timed out during normal startup after
approximately 213 seconds. The trace ended in Codeium's synchronous
`system('gzip -d .../language_server_linux_x64.gz')` first-run bootstrap.
Codeium was loading on `BufEnter`. Fix: defer it to `InsertEnter` and explicitly
call `codeium#command#StartLanguageServer()` from the plugin config. Issue
[#69](https://github.com/brianfiszman/dotfiles/issues/69).

The same trace showed `E216: No such group or event: FileExplorer *` from locked
NvimTree 1.18.0. That is upstream compatibility noise and is explicitly
allowlisted; do not widen the allowlist without a root-cause review.

## Neovim CLI command limit

Run [43499999270](https://github.com/brianfiszman/dotfiles/actions/runs/43499999270)
failed before assertions with:

```
nvim: Too many "+command", "-c command" or "--cmd command" arguments
```

The test passed one `+` option per assertion. Group related Lua into one `+lua`
or a `+luafile`, and keep only independent lazy-load cases in separate
processes.

## Artifact size

A successful run uploaded a 271 MB ZIP because the artifact path included the
entire isolated workspace. Upload only root-level phase logs and relevant XDG
state logs; exclude `data/`, `cache/`, plugin checkouts, and Mason packages.


## LuaSnip native extension overwritten while loaded

On a lazy.nvim cache hit, the forced `:Lazy! build all` pass starts a fresh
Neovim process with the normal config. That config loads LuaSnip and its native
`deps/luasnip-jsregexp.so` extension before the build task runs. At the pinned
LuaSnip revision
[`03c8e67`](https://github.com/L3MON4D3/LuaSnip/tree/03c8e67eb7293c404845b3982db895d59c0d1538),
`make install_jsregexp` copies the freshly built extension directly over that
same destination. `cp` truncates and rewrites the existing inode; it is unsafe
when the process still has the shared object mapped.

The exact cache-hit diagnostic in PR #124 run
[#759](https://github.com/brianfiszman/dotfiles/actions/runs/45939844248)
recorded Neovim loading `LuaSnip/deps/luasnip-jsregexp.so`, then the loader's
first finalizer call at shutdown was for that same library. GDB stopped at
`0x3c40` in `_dl_call_fini`, called by `_dl_fini` and libc `exit()`.
A local Linux reproducer confirmed the filesystem mechanism: `dlopen(A)`,
then `cp B A`, caused exit status 139; copying B to a sibling temporary file
and renaming it over A preserved A's mapped image and its finalizer completed
successfully.

The safe build hook is `snippets.luasnip_build`: it still compiles LuaSnip's
pinned jsregexp submodule and runs on cold and warm paths, but installs the
native extension by copying to a same-directory temporary file and using
`vim.uv.fs_rename` for atomic replacement. The regression
`tests/nvim/luasnip-native-library-replacement.lua` loads a real test shared
object, invokes the same replacement helper, and asserts that the original
loaded library's finalizer runs after Neovim exits. Keep this test wired into
the fast CI cache-contract suite. Do not restore the upstream in-place copy or
skip the configured LuaSnip build hook on cache hits.

## Cross-references

- Workflow/check interpretation:
  [`.agents/skills/github-actions-validation/SKILL.md`](../../.agents/skills/github-actions-validation/SKILL.md)
- Runtime/plugin fingerprints:
  [`neovim-runtime-fingerprints.md`](neovim-runtime-fingerprints.md)
