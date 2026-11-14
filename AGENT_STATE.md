# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Repository:** `brianfiszman/dotfiles`.
- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Current focus: reduce Neovim CI feedback time without weakening clean-install or behavioral coverage.
- **Issue:** [#91 — Reduce Neovim workflow feedback time without weakening coverage](https://github.com/brianfiszman/dotfiles/issues/91), open and in progress under Epic #16.
- **Branch / base:** `feat/ci-feedback-91` → `master`, created from merge commit `9e43312f2afa523e658ed583b4f48bebffb98568` (PR #88).
- **Implemented:** first optimization slice is in [PR #92](https://github.com/brianfiszman/dotfiles/pull/92), now Ready for review, open and unmerged. It includes runner-provisioning optimization, independent fast checks, fail-open PR delta gating, and cancellation-safe integration gating. Issue #91 remains open/in progress.
- **Latest validated implementation/test head:** `aeefc20803016cac2f9f41a640b27d782a161a26` passed PR run [#43643251108](https://github.com/brianfiszman/dotfiles/actions/runs/43643251108). Decision and fast-check jobs passed; fast checks passed 19/19; full isolated preparation, locked plugin restore/build hooks, normal startup, and complete behavior suite passed. The resolved workflow `display_title` records the matching base/head/test SHAs.
- **Manual cold-path details:** run #43634687957 used event `workflow_dispatch` and explicitly logged `workflow_dispatch always runs the cold integration path`. The fresh integration ran without plugin/Mason cache; all three jobs succeeded. Subsequent checkpoint edits are documentation-only and the live branch head in GitHub is authoritative.
- **Initial baseline:** PR #88 run [#43617823749](https://github.com/brianfiszman/dotfiles/actions/runs/43617823749), head `71cd0c6`, approximately 113 seconds total: apt install ~53s, locked plugin restore/build ~26s, normal startup plus behavior suite ~27s; DAP/Mason first-use adapters ~21s within that behavior phase. Single-run observations, not a stable performance estimate.
- **Path-filter finding and resolution:** PR #88's documentation-only checkpoint commits still triggered full integration because `pull_request.paths` evaluates the aggregate PR diff. PR #92 removes the workflow-level PR path filter and uses a fail-open commit-delta gate instead; the later docs-only run #43636243359 confirms fast checks pass and the heavy job is skipped successfully after a prior green integration.
- **First optimization slice:** Ready-for-review PR #92 uses hosted Ubuntu 26.04 toolchains with Go 1.26.11 from the tool cache, dynamically installs only supplemental missing packages, and has an independent fast shell/lockfile job. Earlier full suite runs #43623707000 (`3766490`) and #43624095518 (`f8d3498`) validated the runner change. APT dropped from 428 packages / 116 MB / ~585 MB to 9 packages / 3.64 MB / 12.7 MB. Runner-to-artifact times: 88.95s and 82.50s versus old baseline runs at 109.02s and 135.05s; promising but not controlled due runner/region variance.
- **Review gates:** The stale-base P1 is fixed with exact base/head/test SHAs in a fixed workflow `run-name`, verified via Actions `display_title`. The title-input hardening is committed; its first contract test failed only because its regex over-escaped `${{ }}`. The test now asserts the literal prefix. Exact-head full CI is pending. QA/reviewer roles are simulated by one assistant, not independent humans; no GitHub review is recorded.
- **Prior functional PR:** PR #90 remains open, Draft, and explicitly paused by Brian pending a separate indentation-ownership/setup diagnosis after PR #88. Do not resume or modify PR #90 as part of #91. #91 is the currently authorized active branch; preserve the one-functional-PR cadence and do not open a second functional PR.
- **Cold-path status:** the real manual `workflow_dispatch` cold integration passed on exact implementation/test head `f04ba78` in run #43634687957. The corrected workflow also completed a full fresh PR integration on `408d5a4` in run #43642279636 because prior baselines had no base-SHA marker. The scheduled cron event has not yet fired on the default branch and remains unverified.

## Completed predecessor: PR #88 / Issue #42

- PR [#88](https://github.com/brianfiszman/dotfiles/pull/88) was squash-merged into `master` on 2026-11-14 as [`9e43312`](https://github.com/brianfiszman/dotfiles/commit/9e43312f2afa523e658ed583b4f48bebffb98568); issue [#42](https://github.com/brianfiszman/dotfiles/issues/42) is closed as completed.
- Exact PR head `b08040f52aab1c4dd135ae3a5fd89d7695672ef4` passed pull-request run [#43619768631](https://github.com/brianfiszman/dotfiles/actions/runs/43619768631). The workflow passed pinned Neovim/LuaLS setup, isolated preparation, locked plugin restore/build hooks, normal startup, the full native LSP/Lazydev/Neotest/Go/DAP behavior suite, and artifact upload.
- All four real-LuaLS markers passed: Telescope completion, Neovim API completion, hover for valid Telescope usage, and zero diagnostics for the final valid buffer. Logs artifact [`14122899940`](https://github.com/brianfiszman/dotfiles/actions/runs/43619768631/artifacts/14122899940).
- QA PASS and Senior Reviewer APPROVE were simulated sequential role passes by one assistant, not independent human reviews. A local macOS Neovim API completion/hover parity check remains optional and unverified.

## Completed predecessor: PR #87 / Issue #41

- PR #87 was squash-merged as `a74368456f9c829197aa7569d6cf720b1bc7d9d5`; issue #41 is closed as completed.
- Exact PR-head run [#43604418747](https://github.com/brianfiszman/dotfiles/actions/runs/43604418747) passed; post-merge push run [#43604690496](https://github.com/brianfiszman/dotfiles/actions/runs/43604690496) passed all steps including real locked plugin restore/build and normal startup.
- The original JS/TS ESLint diagnostic reappearing after edit/undo was not reproduced locally. Removing duplicate ESLint publishers removed a credible source but did not prove the exact race resolved; retain as a separate manual follow-up if it recurs.

## Completed LSP implementation decisions (PRs #87 and #88)

- Native LSP from #41 remains: `vim.lsp.config()` / `vim.lsp.enable()`, Mason-LSPConfig `automatic_enable = false`, native `ts_ls`, one configured ESLint diagnostics owner, Conform Ctrl+F.
- **Lazydev:** separate root plugin spec `folke/lazydev.nvim` with `ft = "lua"`; not a dependency of the eagerly loaded LSP plugin.
- Lazydev enables native LSP and nvim-cmp integrations. The five plugin API libraries previously exposed by Neodev remain: `neotest`, `nvim-dap-ui`, `nvim-treesitter`, `plenary.nvim`, and `telescope.nvim`.
- **LuaLS:** explicit LuaJIT runtime, strict module resolution (`runtime.pathStrict = true`), `?.lua` / `?/init.lua` paths, `vim` diagnostics global, function-call snippet completion, Neovim runtime and config Lua libraries. Workspace library paths are a string list so Lazydev can append plugin paths without mixing map/list shapes.
- The separate jsonls `.luarc.json` / `.luarc.jsonc` schema remains unchanged.
- Neodev setup and dependency are removed; `lazy-lock.json` removes `neodev.nvim` and pins Lazydev at `ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d`.
- nvim-cmp includes Lazydev source at `group_index = 0`.

## Validation

| Check | Status | Evidence |
|---|---|---|
| No active Neodev setup/dependency/lock entry | passed | Current diff; LSP/native plugin specs and lockfile inspected; headless assertions confirm the retired module/spec remain unloaded |
| Lazydev remains unloaded outside Lua filetypes and loads on Lua | passed | Dedicated `tests/nvim/lazydev-lazy-loading.lua` in exact-head run #43617823749 |
| `:LazyDev` command registers on Lua filetype | passed | Dedicated Lazydev test, run #43617823749 |
| Five plugin API libraries retained | passed | Dedicated Lazydev test, run #43606193476 |
| Native LSP + nvim-cmp integrations | passed | Dedicated Lazydev test, run #43617823749; scheduled cmp registration is explicitly awaited |
| LuaLS settings and jsonls schema preservation | passed | Headless assertions, run #43617823749 |
| Full isolated preparation and lockfile validation | passed | Run [#43606193476](https://github.com/brianfiszman/dotfiles/actions/runs/43606193476), pull_request event, exact PR head `f472500d8bd79da0ad6eae559291e4fdc7aed745` |
| Locked plugin restore/build hooks | passed | Run #43606193476 |
| Normal Neovim startup | passed | Run #43606193476 |
| Native LSP, Lazydev, Neotest, Go, and DAP behavior scenarios | passed | Run #43606193476; logs show the expected PASS markers |
| Real LuaLS completion for `telescope.builtin.find_files` | passed | Exact-head run [#43617823749](https://github.com/brianfiszman/dotfiles/actions/runs/43617823749); log prints the expected completion PASS marker |
| Real LuaLS completion for `vim.api.nvim_create_autocmd` | passed | Exact-head run #43617823749; request uses a narrow typed prefix and LuaLS returns the method signature |
| Hover after valid edit and clean LuaLS diagnostics | passed | Exact-head run #43617284555; hover resolves `builtin.find_files`, then the final valid buffer has zero diagnostics |
| Full isolated preparation, pinned LuaLS install, lockfile validation, plugin restore/build, normal startup, and behavior suite | passed | Run #43617823749, pull_request event, exact PR head `71cd0c6ddc5e4e00ec0dfa6b5a696649c9cce4b0`; every job step succeeded and logs artifact uploaded |
| Local Telescope API completion/type resolution | partially verified | Brian confirmed `require("telescope.builtin")` and `builtin.find_files` resolve without errors in the interactive Neovim session |
| QA | PASS (simulated) | Rechecked issue #42 acceptance criteria, full PR diff, new real-LuaLS tests, and exact-head CI evidence |
| Senior Reviewer | APPROVE (simulated) | Re-reviewed implementation, workflow, runner wiring, test, lockfile, README, skill, and checkpoint updates; no blocking finding. Not an independent human review. |
| Local Neovim API completion and hover on macOS | unverified locally | Both APIs and hover are now exercised in exact-head CI; a local Mac session remains an optional environment-parity check |
| PR #88 merge | not authorized | Requires Brian's explicit approval |

### Earlier CI attempts and correction

- Runs #43605503484, #43605709646, and #43606069295 were cancelled when newer commits superseded their heads. #436055/#436057 were cancelled before full validation; #436060 completed restore but was cancelled before startup.
- Run [#43605876070](https://github.com/brianfiszman/dotfiles/actions/runs/43605876070) on predecessor source SHA `43fb08c` passed restore and normal startup, then failed on a test-only assumption that lazy.nvim always stores `ft` as an array. The actual valid spec retains `ft = "lua"` as a string. The test was corrected to accept either string or list; the exact current-head run #43606193476 passed.

## Next concrete actions

1. Verify that a docs-only follow-up reads successful run #43643251108 metadata from `display_title`, matches the exact current base SHA, and skips only the heavy integration job.
2. Re-run Senior Reviewer against the final complete diff and report the simulated role result honestly.
2. Re-run the Senior Reviewer pass against the corrected complete diff; keep the assistant's review explicitly labeled as simulated, not an independent human review.
3. Keep PR #92 open and unmerged until Brian explicitly authorizes the merge.
3. Keep the cold prepare → locked restore/build hooks → normal startup contract. Schedule execution remains to be observed on `master`; defer plugin/Mason cache and behavior-suite parallelism until build hooks and mutable XDG/Mason isolation are proven.
4. Keep PR #90 Draft/paused until its separate indentation-ownership/setup diagnosis is completed; do not mix it into #91.

## Scope boundaries

- Current Sprint 2 functional item: #91, estimate M; the first runner/fast-check/delta-gating slice is implemented and cold-path validated in Ready-for-review PR #92 on `feat/ci-feedback-91`. Broader plugin/Mason cache and safe behavior parallelization remain deferred investigation; issue #91 is not complete.
- #44 (Treesitter API/branch migration), #76 (Telescope lazy-loading), #40 (Run with Args), and broad plugin inventory/update remain outside this PR.
- No bulk plugin update.
- PR #83 remains open/unmerged as a historical Sprint 1 planning checkpoint.

## Continuity rules

- Live GitHub PR, branch, issue, and Actions state are authoritative.
- Validate exact code/test HEAD and workflow event; later documentation-only commits can still trigger PR workflows when the aggregate PR diff matches path filters.
- Keep `AGENT_WORKLOG.md` append-only.
- Specialist skills: `.agents/skills/neovim-maintenance/SKILL.md`, `.agents/skills/github-actions-validation/SKILL.md`, `.agents/skills/execution-continuity/SKILL.md`, `.agents/skills/scrum-team/SKILL.md`.
