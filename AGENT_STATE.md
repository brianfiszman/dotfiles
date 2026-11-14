# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize the LSP foundation using one native Neovim setup/activation path per server while preserving supported workflows.
- **Issue:** [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41), estimate M.
- **PR:** [#87](https://github.com/brianfiszman/dotfiles/pull/87), open and unmerged.
- **Branch:** `feat/lsp-native-setup-41`.
- **Base:** `master` at `c587c8854faf2e99770ca6f30a51a529a38140bb`.
- **Latest functional code/test head:** `380e35d0960aad312d23c2cd8509c42fb4f6d721`.
- **Exact-head validation:** [Actions run #43600645750](https://github.com/brianfiszman/dotfiles/actions/runs/43600645750) completed successfully on the exact code/test head above.
- **Merge:** not authorized. Brian must explicitly authorize PR #87; no merge has occurred.

## Sprint 2 implementation (#41)

- Replaced lsp-zero orchestration and direct legacy lspconfig setup calls with native `vim.lsp.config()` and one explicit `vim.lsp.enable()` activation path.
- Configured Mason-LSPConfig with `automatic_enable = false`; Mason installs packages, while native LSP configuration owns activation.
- Consolidated server-specific overrides so each configured server has one setup owner.
- Replaced TypeScript Tools with native `ts_ls`; retained function-call completions, references/implementations CodeLens, CodeLens refresh hooks, and the lockfile-based workspace root policy.
- Moved nvim-cmp Tab/Shift-Tab behaviour off lsp-zero and preserved the LuaSnip behaviour.
- Updated only LSP-related dependency versions; no repository-wide plugin update. Neovim minimum/CI baseline is 0.11.3.
- Neodev remains temporarily for #42; its compatibility helper still imports `lspconfig.util`. Remove that transitional dependency in the separate lazydev migration.
- Preserved custom server behaviour: ESLint save-time fixes, Svelte JS/TS change notification, Docker Compose root/filetype, Go gofumpt, YAML schemas, JSON LuaLS schema, and Lua Neodev integration.
- Preserved LSP keymaps: `K` hover, `F3` format buffer/selection, `Ctrl-Shift-F` synchronous format, `<leader>DF` diagnostic float, `[d` / `]d` navigation, `<leader>D` Telescope diagnostics, and the existing navigation/refactor actions.
- **Diagnostic display preference:** inline diagnostic text is enabled through `virtual_text = { spacing = 2, source = "if_many" }`, with gutter signs and diagnostic floats retained. The LSP module intentionally does not set `update_in_insert`; Bufferline owns that global preference and sets it to true.
- Brian manually confirmed that completion works and `K` shows symbol information. He does not recall using proprietary `:TSTools*` commands; no compatibility shim is planned.
- Still needs manual validation in Brian's editor: `F3` formatting and the visible inline diagnostic text. Representative project attachment, TypeScript/ESLint behaviour, and interactive macOS behaviour remain manual coverage items.

## Validation and review

| Gate | Status | Evidence |
|---|---|---|
| Isolated preparation / installer safety | passed | Run #43600645750 |
| Neovim v0.11.3 install | passed | Run #43600645750 |
| lazy-lock JSON validation | passed | Run #43600645750 |
| Locked plugin restore and configured build hooks | passed | Run #43600645750 |
| Normal Neovim headless startup | passed | Run #43600645750 |
| Native LSP assertions | passed | Run #43600645750; inline virtual-text table, server ownership, activation, special settings |
| Neotest, Go, DAP regressions | passed | Run #43600645750 |
| QA | PASS | Final PR diff and issue #41 acceptance criteria reviewed |
| Senior Reviewer | APPROVE | Separate final complete-diff review; no blocking findings |
| Manual editor validation | pending | Brian to validate F3 and inline messages in a representative local project |
| PR #87 merge | not authorized | Requires Brian's explicit approval |

QA and Senior Reviewer were separate sequential simulated passes by the assistant, not independent human reviewers.

### CI correction history

- Earlier predecessor head `131b8c3831dc2dfce243bc611c3dfe992fec8b0a` also passed run #43598472873.
- The first test after enabling inline virtual text exposed a stale assertion that `update_in_insert` must be false. The real config in `.config/nvim/lua/navigation/bufferline.lua` sets it true. Removed the duplicate LSP-level assignment and the incorrect assertion; Bufferline remains the sole owner of that preference.
- The final run #43600645750 on `380e35d0960aad312d23c2cd8509c42fb4f6d721` completed successfully and exercised the corrected assertion.

## Sprint scope boundaries

- #41 is the only committed functional issue for Sprint 2.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and the broader dependency inventory/update remain outside this PR.
- Do not perform an indiscriminate bulk plugin update.
- PR #83 remains open/unmerged as a historical planning checkpoint.

## Continuity and validation rules

- Treat live GitHub PR, branch, commit, and Actions state as authoritative; verify this checkpoint before resuming.
- For every runtime change, validate the exact PR code/test head, not a predecessor SHA.
- Inspect all jobs/steps and logs; a pending job is not a hang, and an in-progress run is neither pass nor failure.
- Avoid commits while a run is active; workflow concurrency can cancel the superseded run.
- Keep QA and Senior Reviewer passes separate. Never merge without explicit authorization for this PR.
- Keep `AGENT_WORKLOG.md` append-only. Skills:
  - `.agents/skills/neovim-maintenance/SKILL.md`
  - `.agents/skills/github-actions-validation/SKILL.md`
  - `.agents/skills/execution-continuity/SKILL.md`
