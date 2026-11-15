# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

## Current task — issue #89: scope-aware indentation for S, o and O

- **Repository:** `brianfiszman/dotfiles`.
- **Issue / PR:** [#89](https://github.com/brianfiszman/dotfiles/issues/89) / [#90](https://github.com/brianfiszman/dotfiles/pull/90), branch `fix/indented-substitute-43` → `master`.
- **Base:** `7857e8774471d4a756190e73d563ea4f537782d5`.
- **Live PR state at checkpoint:** PR #90 is open, Draft, and unmerged. No merge authorization exists.
- **Latest implementation/test head inspected:** `198ccdd907206399d9b4db87d35bb9610c2b5d6e`; exact-head workflow [#43672262947](https://github.com/brianfiszman/dotfiles/actions/runs/43672262947) failed in the behavior phase. The docs-only skill update `94b18c617fa59cf04d1029a659a3295cf2b044be` is now the branch head; it does not change production behavior. Re-read live PR and CI after every subsequent update.
- **Validated portions of run #43672262947:** clean preparation, pinned toolchain, locked plugin restore/build hooks, and normal startup passed. The behavior log confirms deterministic `S`, `o`, `O`, counted `2S`, and Lua Treesitter `S` pass.
- **Current failing behavior:** TypeScript Treesitter `o` calculates and applies the correct two-space prefix, but the new line is row 4 instead of the expected row 3. The artifact [14145260788](https://github.com/brianfiszman/dotfiles/actions/runs/43672262947/artifacts/14145260788) shows the current path: calculate source indentation, schedule dispatch, run `:normal! o` with `indentexpr` temporarily disabled, receive `InsertEnter`, apply the prefix, restore `indentexpr`, and call `:startinsert!`. The observed callback row is still 4. This proves the prefix calculation is not the failing part; the line-creation / Insert-mode lifecycle is.
- **Do not overstate the root cause:** the suspected interaction between `:normal! o`, the first InsertEnter/InsertLeave cycle, and explicit `:startinsert!` has not yet been isolated. The existing code comments assume that two-entry sequence, but the logs have not proved which command inserts/selects the unexpected fourth row.
- **Next diagnostic:** add temporary, scoped event tracing before the native open command. Count and log every `InsertEnter`/`InsertLeave` with mode, cursor row/column, line count, current line and `indentexpr`; snapshot immediately before/after `:normal! o`, before/after `:startinsert!`, and once the event loop settles. Compare (a) a minimal fixed-indentexpr fixture and (b) real TypeScript Treesitter. Also compare native `:normal! o` without an explicit `:startinsert!`. Do not add another cursor/line workaround until this proves where row 4 is introduced.
- **Indentation ownership:** `core/general.lua` configures native autoindent and filetype indentation. `treesitter.lua` enables nvim-treesitter indentation; at pinned revision `85168f15808d89b0222313652b9d2777eda3cb08`, it attaches `nvim_treesitter#indent()` only when the parser language has an `indents` query. Lua has a dedicated query; TypeScript inherits ECMA. Indent-blankline and mini.indentscope are visual guides, not indentation providers.
- **Current implementation scope:** Normal-mode `S`, `o`, and `O` mappings live in `.config/nvim/lua/core/general.lua`; the async regression is `tests/nvim/indented-substitute.lua` and is invoked by `scripts/test-nvim-headless.sh`. The test uses real `nvim_input()`, deferred callbacks, and bounded waits; its final callback exits via `os.exit(0, true)`, and assertion failures via `os.exit(1, true)`.
- **Skill improvement:** `.agents/skills/neovim-maintenance/SKILL.md` already had the parser-backed mapping playbook from `b7fb512`. Extended it in `94b18c6` with a concrete diagnostic protocol for `:normal!` / InsertEnter / InsertLeave / `:startinsert!` boundaries, event counts, snapshots, and minimal fixed-vs-parser provider comparisons. Do not create a duplicate skill.
- **Definition of done:** deterministic and real Lua/TypeScript parser-backed tests pass on the exact code/test head; full isolated install, locked plugin restore/build hooks, normal startup and behavior suite pass; full diff reviewed; interactive macOS validation reported separately as unverified.
- **Manual limitation:** verify mappings in real Lua and TypeScript project buffers on the maintainer's macOS Neovim session after CI passes.
- **Merge:** keep PR #90 Draft. No merge without Brian's explicit instruction.

## Next concrete actions

1. Instrument the actual InsertEnter/InsertLeave lifecycle around `:normal! o` and `:startinsert!` using a temporary scoped trace; record event counts and row/line-count changes.
2. Add a minimal fixed-indentexpr reproduction and compare it with the real TypeScript Treesitter case. Remove the tracing once the responsible transition is proven.
3. Apply the smallest production correction only after the reproducer identifies where row 4 is created or selected.
4. Re-run the exact-head workflow and inspect `indented-substitute.log` for deterministic, Lua, TypeScript `o`, and TypeScript `O` PASS markers plus the final row/column/indent.
5. Re-review PR #90's complete diff and preserve the manual macOS validation caveat. Keep the PR Draft and unmerged.

---
## Completed predecessor — PR #92 / Issue #91

- PR [#92](https://github.com/brianfiszman/dotfiles/pull/92) was squash-merged into `master` on 2026-11-14 as [`7857e8774471d4a756190e73d563ea4f537782d5`](https://github.com/brianfiszman/dotfiles/commit/7857e8774471d4a756190e73d563ea4f537782d5).
- Post-merge `push` run [#43645352151](https://github.com/brianfiszman/dotfiles/actions/runs/43645352151) passed all three jobs, including full fresh install, pinned Neovim/LuaLS, locked plugin restore/build hooks, normal startup, behavior suite, and artifact upload.
- The weekly cron remains intentionally deferred until the currently planned feature work is complete. Do not change it in this issue.

## Next concrete actions

1. Run the deferred `nvim_input()` state-machine test on the exact PR head; confirm the artifact contains `indented-substitute.log` and PASS markers for deterministic S/o/O/2S and real Lua/TypeScript Treesitter behavior using computed indentation expectations.
2. Inspect the trace markers and any failure at the exact operation; keep production mappings unchanged unless tests prove a defect.
3. Run the full isolated Neovim workflow on the exact final code/test head.
4. Re-review PR #90's complete diff against issue #89 and report QA findings plus the manual macOS limitation.
5. Keep PR #90 Draft until implementation and CI evidence are clean; merge still requires Brian's explicit authorization.

---

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

1. Await Brian's explicit merge authorization. PR #92 is open, Ready for review, mergeable, and unmerged; no merge is authorized.
2. After merge, verify the new `push.paths` triggers on `master` (including `scripts/ci/**` and `tests/ci/**`) and observe the scheduled cold run on the default branch.
3. Keep plugin/Mason caching and behavior-suite parallelization deferred until configured build hooks on cache hits and mutable XDG/Mason isolation are proven.
4. Keep PR #90 Draft/paused for its separate indentation-ownership/setup diagnosis; do not mix it into #91.

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
