# CI failure fingerprints

Historical, repository-specific observations. They are not universal rules; use
them to recognize a layer faster, then verify against the current workflow and
logs.

## Workflow parse: \`runner\` context at job level

The Neovim workflow set \`NVIM_TEST_DIR: \${{ runner.temp }}/...\` in the job-level
\`env\`. GitHub rejected the workflow before execution with
\`Unrecognized named-value: 'runner'\`. Moving the expression to the test step's
\`env\` fixed it. Run
[43475125584](https://github.com/brianfiszman/dotfiles/actions/runs/43475125584).

## Neorg / LuaRocks: missing Lua 5.1

The restore failed because the Hererocks environment lacked Lua 5.1. CI installs
\`lua5.1\` and \`liblua5.1-0-dev\` while preserving \`rocks = { hererocks = true }\`.
Do not disable Hererocks or skip native parser builds to get green CI.

## Neorg parser discovery

Installing the rocks was not enough: \`lazy-rocks\` parser directories were not on
Neovim's runtimepath. PR #71 declares \`tree-sitter-norg\` and
\`tree-sitter-norg-meta\` as dependencies, prepends their Lua 5.1 runtime
directories before \`neorg.setup()\`, and asserts both parsers are discoverable
and loadable.

## Go helper false green

Run [43490592093](https://github.com/brianfiszman/dotfiles/actions/runs/43490592093)
passed while logging \`Vim:install golines failed:\`. \`go.nvim\`'s bulk
\`update_all_sync()\` hook attempted optional binary installs, and the plugin
notification did not make Neovim exit nonzero. PR #71 removed the bulk hook from
default setup and makes the smoke test fail on that notification signature
during restore.

## Workspace preflight ran after initialization

Run [43481043006](https://github.com/brianfiszman/dotfiles/actions/runs/43481043006)
failed with \`NVIM_TEST_DIR must be empty before the prepare phase\`. The script
created \`$HOME\` and XDG directories before calling \`prepare()\`, so the emptiness
check could never pass. Fix commit
[10dfd2d](https://github.com/brianfiszman/dotfiles/commit/10dfd2d3969e9e6ffbdd03bbbc67668c4ad7f778):
move the preflight to top-level setup before any \`mkdir\`, and keep it limited to
\`prepare\`/\`all\`.

## Clean-start timeout in Codeium bootstrap

Run [43485726816](https://github.com/brianfiszman/dotfiles/actions/runs/43485726816)
passed preparation and restore, then timed out during normal startup after
approximately 213 seconds. The trace ended in Codeium's synchronous
\`system('gzip -d .../language_server_linux_x64.gz')\` first-run bootstrap.
Codeium was loading on \`BufEnter\`. Fix: defer it to \`InsertEnter\` and explicitly
call \`codeium#command#StartLanguageServer()\` from the plugin config. Issue
[#69](https://github.com/brianfiszman/dotfiles/issues/69).

The same trace showed \`E216: No such group or event: FileExplorer *\` from locked
NvimTree 1.18.0. That is upstream compatibility noise and is explicitly
allowlisted; do not widen the allowlist without a root-cause review.

## Neovim CLI command limit

Run [43499999270](https://github.com/brianfiszman/dotfiles/actions/runs/43499999270)
failed before assertions with:

\`\`\`
nvim: Too many "+command", "-c command" or "--cmd command" arguments
\`\`\`

The test passed one \`+\` option per assertion. Group related Lua into one \`+lua\`
or a \`+luafile\`, and keep only independent lazy-load cases in separate
processes.

## Artifact size

A successful run uploaded a 271 MB ZIP because the artifact path included the
entire isolated workspace. Upload only root-level phase logs and relevant XDG
state logs; exclude \`data/\`, \`cache/\`, plugin checkouts, and Mason packages.

## PR #124 macOS Terminal.app focus: possible click-target occlusion

**Status: hypothesis only; no root cause confirmed.** On PR #124 head
\`ff84ba7a9af554e71be7524876263de284d00c8d\`, run
[#712](https://github.com/brianfiszman/dotfiles/actions/runs/45877998509)
(attempt 2), macOS job
[140114434442](https://github.com/brianfiszman/dotfiles/actions/runs/45877998509/job/140114434442)
passed locked plugin restore and all five Avante native-library checks. The
focus helper launched Neovim in a real Terminal.app TTY (\`/dev/ttys000\`) and
observed its \`UIEnter\` readiness marker. It then activated Finder and verified
Finder as the frontmost app. A native click was posted at the center of Terminal
window 29 (bounds \`(40, 57, 585, 371)\`) using
\`combinedSessionState\`; Terminal did not become frontmost, Finder remained
active, and no \`FocusGained\` event was observed. The dependent Python-provider
step was skipped.

Static review found a possible fixture-level occlusion path in
\`scripts/test-macos-terminal-focus.sh\`: immediately before clicking Terminal,
the test runs \`open -a Finder "$test_root"\`. This activates Finder **and opens
the fixture folder in Finder**. The subsequent Swift helper filters the
\`CGWindowListCopyWindowInfo(.optionOnScreenOnly, ...)\` result down to Terminal
windows, checks that the click is inside the Terminal window's own bounds, and
does not inspect windows above the target. Apple documents that
\`optionOnScreenOnly\` returns windows from front to back:
[Apple API contract](https://developer.apple.com/documentation/coregraphics/cgwindowlistoption/optiononscreenonly).
A Finder folder window may therefore cover the click point while the Terminal
window remains present in the on-screen list. This is plausible, not established:
the current logs do not include the complete window stack or Finder window
bounds at click time.

**Next discriminating check:** immediately before posting the event, collect the
full on-screen window list in z-order and log each window's owner/PID, ID, layer,
name, and bounds. Find the target Terminal window's index and report every
window above it whose bounds intersect the click point. Do not try another
event source, click coordinate, or activation API before this native
visibility/occlusion check. Keep the assertion on a real Neovim TTY focus
autocmd; never synthesize Neovim focus bytes.

The cold plugin-restore phase and the macOS focus assertion are independent:
plugin restore/Avante artifacts passed; the focus transition remains unverified.
This is the current macOS priority, separate from the Linux cache-hit crash.

## PR #124 Linux cache-hit forced-build SIGSEGV: task-count observation

On the same exact PR head and run #712, Linux restored the lazy.nvim and
Tree-sitter caches successfully. The separate \`plugin-cache-build\` command
(\`+Lazy! build all\`) created and completed **93** Lazy build tasks before the
Neovim child exited with SIGSEGV after the explicit task/error and configured
hook assertions. The cold restore in run
[#711](https://github.com/brianfiszman/dotfiles/actions/runs/45877323621)
created 9 build tasks; the cache-hit restore itself in #712 created 3 before
the separate forced pass.

At the pinned lazy.nvim revision, \`Manage.build()\` sets \`force = true\`, and
the build-task skip predicate returns \`false\` for every plugin when forced.
The runner therefore constructs a task for every plugin, including plugins
without a build function/file. Even these no-op tasks pass through task
creation/completion and schedule Lazy render/plugin events. This is a concrete
difference between normal restore and \`build all\`; it is **not yet a proven
cause** of the SIGSEGV. No further Linux CI retry is authorized by the
two-attempt stop rule; a native backtrace/local reproduction is still required.
Keep this investigation secondary to the macOS focus work.

## Cross-references

- Workflow/check interpretation:
  [\`.agents/skills/github-actions-validation/SKILL.md\`](../../.agents/skills/github-actions-validation/SKILL.md)
- Runtime/plugin fingerprints:
  [\`neovim-runtime-fingerprints.md\`](neovim-runtime-fingerprints.md)
- Bounded diagnostic method:
  [\`.agents/skills/diagnostic-experiments/SKILL.md\`](../../.agents/skills/diagnostic-experiments/SKILL.md)
