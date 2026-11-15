# Neovim Configuration Modernization

Tracking issue: [#16 — Neovim configuration modernization](https://github.com/brianfiszman/dotfiles/issues/16)

The backlog is organized around changes the user can observe. Keep one issue per
independently testable behavior; do not create multiple tickets for the same
underlying fix.

## P0 — Make a fresh setup safe and reproducible

- [#31 Make lazy.nvim bootstrap failures clear and actionable](https://github.com/brianfiszman/dotfiles/issues/31) — success path is covered; missing-Git and failed-clone error paths still need focused tests.
- [#66 Exclude the committed Python virtual environment from installation](https://github.com/brianfiszman/dotfiles/issues/66) — installer exclusion is merged; Python provider health still needs a real runtime check.

## P1 — Make everyday editing predictable

- [#89 Make S, o and O enter at the current scope indentation](https://github.com/brianfiszman/dotfiles/issues/89) — initial `feedkeys` tests exposed two harness issues (implicit Escape, then synchronous Insert-mode wait); the non-blocking `nvim_input()` correction is under exact-head CI validation. Treesitter ownership is documented; manual Lua/TypeScript macOS verification remains required.


- [#32 Stop automatically unlinking snippets when the cursor is idle](https://github.com/brianfiszman/dotfiles/issues/32)
- [#33 Avoid running checktime every time a buffer window is entered](https://github.com/brianfiszman/dotfiles/issues/33)
- [#34 Remove full helptags generation from every Neovim startup](https://github.com/brianfiszman/dotfiles/issues/34)
- [#35 Use one scroll-animation system instead of three](https://github.com/brianfiszman/dotfiles/issues/35)
- [#36 Choose one intentional default for line wrapping](https://github.com/brianfiszman/dotfiles/issues/36)
- [#37 Run one chosen linter per language instead of duplicate tools](https://github.com/brianfiszman/dotfiles/issues/37)
- [#38 Reduce repeated lint runs while typing and opening files](https://github.com/brianfiszman/dotfiles/issues/38)
- [#39 Define Tab and Shift-Tab behavior only once](https://github.com/brianfiszman/dotfiles/issues/39)
- [#69 Load Codeium when entering insert mode, not when opening any buffer](https://github.com/brianfiszman/dotfiles/issues/69) — empty-buffer deferral is validated; the first InsertEnter activation remains unverified.

## P1 — Keep language and navigation tools reliable

- [#40 Make the Run with Args keymap actually pass debug arguments](https://github.com/brianfiszman/dotfiles/issues/40)
- [#41 Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41) — completed in PR #87.
- [#42 Replace the archived neodev plugin with lazydev](https://github.com/brianfiszman/dotfiles/issues/42)
- [#43 Load testing, debugging, and search tools only when used (tracking parent)](https://github.com/brianfiszman/dotfiles/issues/43)
- [#76 Load Telescope and its extensions on the first picker action](https://github.com/brianfiszman/dotfiles/issues/76)
- [#44 Pin the Treesitter API and make parser updates predictable](https://github.com/brianfiszman/dotfiles/issues/44)
- [#45 Make shell, font, and clipboard settings portable](https://github.com/brianfiszman/dotfiles/issues/45)


## Completed — PR #71 merged on 2026-11-13

[PR #71](https://github.com/brianfiszman/dotfiles/pull/71) was squash-merged
into `master` as [`8e721cd`](https://github.com/brianfiszman/dotfiles/commit/8e721cddee895a12367184fca1d588fbee9e1f4f).

The runtime code head `f1273d8cab4b3c0aec090abee20e22cd45fce2f5` passed
[Actions run #43504068345](https://github.com/brianfiszman/dotfiles/actions/runs/43504068345):
isolated installer preparation, locked plugin restore/build hooks, normal headless
startup, and behavioral checks for Go's `CmdlineEnter`, `go`, and `gomod`
triggers. The artifact was uploaded successfully.

Completed issues:
- [#26](https://github.com/brianfiszman/dotfiles/issues/26) — remove obsolete dein.vim setup.
- [#27](https://github.com/brianfiszman/dotfiles/issues/27) — preserve existing configs with backups.
- [#28](https://github.com/brianfiszman/dotfiles/issues/28) — keep OS package installation out of the dotfiles installer.
- [#29](https://github.com/brianfiszman/dotfiles/issues/29) — make Neovim/Emacs install modes explicit.
- [#30](https://github.com/brianfiszman/dotfiles/issues/30) — clean isolated install and headless smoke test.
- [#70](https://github.com/brianfiszman/dotfiles/issues/70) — load Go tooling only for Go filetypes.
- [#72](https://github.com/brianfiszman/dotfiles/issues/72) — keep optional Go binaries out of default restore.
- [#73](https://github.com/brianfiszman/dotfiles/issues/73) — make Norg parsers discoverable and loadable.

Still open after the merge:
- [#31](https://github.com/brianfiszman/dotfiles/issues/31) — test missing-Git and failed-clone bootstrap paths.
- [#34](https://github.com/brianfiszman/dotfiles/issues/34) — verify help tags remain discoverable after a clean install.
- [#66](https://github.com/brianfiszman/dotfiles/issues/66) — verify the Python provider in a real Neovim runtime.
- [#69](https://github.com/brianfiszman/dotfiles/issues/69) — verify the first InsertEnter activation and Codeium startup.

## Completed — PR #77 merged on 2026-11-13

[PR #77](https://github.com/brianfiszman/dotfiles/pull/77) implements
[#75 — DAP lazy-loading](https://github.com/brianfiszman/dotfiles/issues/75)
and was squash-merged into `master` as
[`b30cf6f`](https://github.com/brianfiszman/dotfiles/commit/b30cf6f87dc1a8adbd573a25c712f540db2e548a).

The final PR head
`73b4bf80f811667a778f2105dfd9516aae3bfce4` passed the full isolated workflow
in [Actions run #43530295202](https://github.com/brianfiszman/dotfiles/actions/runs/43530295202).
The run was a `pull_request` event for that exact head and passed isolated
preparation, locked plugin restore/build hooks, normal startup, Go lazy-loading,
the first-use Mason `:DapInstall` path, DAP key activation, native DAP command
triggers, and Neotest's Debug Test mapping. All five configured Mason adapters
reached successful or already-installed terminal states. The logs artifact
was 255,173 bytes.

The DAP test now observes Mason package-handle and terminal install events
rather than repeatedly polling `Package:is_installed()` while installs are in
progress. An earlier callback trace showed a scheduled callback entering but
not returning for more than four minutes; the exact blocking function was not
captured, so the root cause is not claimed as proven. The event-driven test
passed and removed the repeated filesystem scan from its wait predicate.

Issue #75 is closed as completed. The existing Run with Args defect remains
separate in [#40](https://github.com/brianfiszman/dotfiles/issues/40). No
`lazy-lock.json` changes were included. Interactive macOS behavior and a live
TypeScript debugging session were not tested by CI.

## Completed — PR #84 merged on 2026-11-13

[PR #84](https://github.com/brianfiszman/dotfiles/pull/84) implements
[#74 — Neotest lazy-loading](https://github.com/brianfiszman/dotfiles/issues/74)
and was squash-merged into `master` as
[`110c365`](https://github.com/brianfiszman/dotfiles/commit/110c3658085c4c23d847de361a08b5e15e72b605).

The final PR head
`f4b9f2744e65a23cbf8a6600abfefcc4ca75bf12` passed pull-request run
[#43542407243](https://github.com/brianfiszman/dotfiles/actions/runs/43542407243).
The run passed isolated preparation, locked plugin restore/build hooks, normal
Neovim startup, Neotest lazy-loading, Go regressions, Mason/DAP lazy-loading,
and the Debug Test trigger. Logs confirm the callback-backed `<Space>ts`
trigger loads Neotest, vim-test, and configured adapters while ordinary test
actions leave DAP unloaded.

**QA PASS** and **Senior Reviewer APPROVE** were recorded before merge. The
Scrum roles were performed sequentially by one assistant, not independent human
reviewers. Test Stop and Debug Test were dispatched in headless tests; the
other four preserved mappings were confirmed by static review. No representative
project suite or interactive macOS session was performed. No lockfile or plugin
version changes were included. Issue #74 is closed as completed.

## Completed — PR #88 merged on 2026-11-14

[PR #88](https://github.com/brianfiszman/dotfiles/pull/88) implements
[#42 — Replace Neodev with Lazydev](https://github.com/brianfiszman/dotfiles/issues/42)
and was squash-merged into `master` as
[`9e43312`](https://github.com/brianfiszman/dotfiles/commit/9e43312f2afa523e658ed583b4f48bebffb98568).
Issue #42 is closed as completed.

Exact PR head `b08040f52aab1c4dd135ae3a5fd89d7695672ef4` passed pull-request
workflow [#43619768631](https://github.com/brianfiszman/dotfiles/actions/runs/43619768631).
The full isolated workflow passed pinned Neovim/LuaLS setup, installer preparation,
locked plugin restore/build hooks, normal startup, and the native LSP, Lazydev,
Neotest, Go, and DAP behavior suite. Real LuaLS completion for Telescope and
Neovim APIs, hover after a valid edit, and zero diagnostics all passed. Artifact
[`14122899940`](https://github.com/brianfiszman/dotfiles/actions/runs/43619768631/artifacts/14122899940)
contains the logs. QA and Senior Review were sequential simulated passes by one
assistant, not independent human reviews. Optional macOS Neovim API completion/
hover parity remains unverified.

## Current handoff — Sprint 2: reduce Neovim CI feedback time

**Sprint Goal:** reduce redundant CI work and surface fast feedback earlier without
weakening locked-install, normal-startup, LuaLS, or behavioral coverage.

- **Current issue:** [#91 — Reduce Neovim workflow feedback time without weakening coverage](https://github.com/brianfiszman/dotfiles/issues/91), estimate **M**, still open/in progress under Epic #16.
- **Active branch / PR:** `feat/ci-feedback-91` → [PR #92](https://github.com/brianfiszman/dotfiles/pull/92), now Ready for review, open and unmerged; base `master` at merge commit [`9e43312`](https://github.com/brianfiszman/dotfiles/commit/9e43312f2afa523e658ed583b4f48bebffb98568).
- **Validated implementation/test head:** `f04ba78b487e1b2e282432bcca78f5e4609d721a`. The later handoff/checkpoint edits are documentation-only; exact latest branch head is authoritative in GitHub.
- **Implemented first slice:** preinstalled Ubuntu 26.04 toolchains, Go 1.26.11 from the hosted tool cache, dynamic supplemental APT detection, runner preflight, an independent fast shell/lockfile/unit-test job, PR commit-delta gating with fail-open behavior, and cancellation-safe integration gating using `!cancelled()`.
- **Cold path validated:** manual `workflow_dispatch` run [#43634687957](https://github.com/brianfiszman/dotfiles/actions/runs/43634687957) ran against exact implementation/test head `f04ba78`. All three jobs passed: decision, fast checks, and fresh install/headless integration. Fast checks passed 14/14 Node tests. The integration ran from a fresh isolated workspace without plugin/Mason cache, restored locked plugin revisions with configured build hooks enabled, and started Neovim normally. Artifact [14129361921](https://github.com/brianfiszman/dotfiles/actions/runs/43634687957/artifacts/14129361921).
- **Behavior coverage preserved:** real Lazydev lazy loading and plugin API setup passed; real pinned LuaLS returned `telescope.builtin.find_files` and `vim.api.nvim_create_autocmd`, resolved hover on valid Telescope usage, and reported zero diagnostics. Neotest, Go, DAP lazy-loading/commands, and first-use installation of all five Mason adapters also passed. The existing `tests/nvim/lazydev-lazy-loading.lua` and `tests/nvim/lazydev-luals-completion.lua` were not changed or weakened in this PR.
- **Runner provisioning improvement:** baseline runs installed 428 packages, downloaded 116 MB, and added about 585 MB; optimized samples installed 9 packages, downloaded 3.64 MB, and added 12.7 MB. Runner-to-artifact observations were ~88.95s and ~82.50s versus old samples ~109.02s and ~135.05s. These are promising but not controlled benchmarks because hosted runner regions/network differed.
- **PR delta gate:** only a successful prior full integration for this same PR can be used as a baseline. Any missing/wrong baseline, API error/incomplete response, relevant change, rename, divergence, or capped/incomplete comparison fails open to the full suite. Only an explicit successful decision with output exactly `false` skips the heavy job; decision failures still require integration.
- **Review gates:** QA **PASS** and Senior Reviewer **APPROVE** on the exact implementation/test head, both sequential simulated roles performed by one assistant as required by `.agents/skills/scrum-team/SKILL.md`. These are not independent human reviews. No GitHub reviewer or team is currently requested; no CODEOWNERS file or verified reviewer handle/team slug was found.
- **Still open:** scheduled cron execution has not yet fired on the default branch. Broad plugin/Mason caching remains deferred because a clean cached checkout may skip lazy.nvim build hooks. Behavior-suite parallelization remains deferred until mutable XDG/plugin/Mason state is isolated. These are not represented as completed.
- **Paused independent work:** [PR #90](https://github.com/brianfiszman/dotfiles/pull/90) remains Draft/paused by Brian pending the separate indentation-ownership/setup diagnosis for [#89](https://github.com/brianfiszman/dotfiles/issues/89). It is not part of #91 and must remain untouched.

## Mandatory testing standard

Testing is included in every functional issue's scope and estimate. Issues must define observable, behavior-first acceptance scenarios and the automated unit/integration/end-to-end checks appropriate to the change. For interactive Neovim behavior, prefer real headless local-like tests that exercise the actual configuration, plugin/LSP/tool trigger, and user-visible result; mocks or startup-only checks are not enough. Required checks run in CI on explicit relevant triggers. Manual validation supplements automation and is required only for behavior that cannot reasonably be automated, with exact steps and rationale documented. A task is not done until its behavior tests and relevant regression suite pass on the exact change.

## Working agreement

- Each ticket describes a visible problem, desired behavior, scope, and acceptance
  criteria.
- Preserve current workflows and keymaps unless the issue explicitly changes them.
- Do not mass-update plugins as part of an unrelated fix.
- Measure startup before and after; do not claim a speedup without measurements.
- Separate Linux headless results from macOS interactive validation.
- Use `AGENTS.md` and [the Neovim maintenance skill](../.agents/skills/neovim-maintenance/SKILL.md)
  as the repository's working agreement.
- Use the [GitHub Actions validation skill](../.agents/skills/github-actions-validation/SKILL.md)
  to trace workflow runs by exact commit and event.
- Use the [execution continuity skill](../.agents/skills/execution-continuity/SKILL.md)
  to recover and persist multi-step work.
