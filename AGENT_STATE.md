# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Repository:** `brianfiszman/dotfiles`.
- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize native LSP ownership and make editor behavior consistent.
- **Issue / PR:** [#41](https://github.com/brianfiszman/dotfiles/issues/41) / [PR #87](https://github.com/brianfiszman/dotfiles/pull/87). Both remain open; PR is not merged.
- **Branch / base:** `feat/lsp-native-setup-41` → `master`, base SHA `c587c8854faf2e99770ca6f30a51a529a38140bb`.
- **Code/test snapshot:** `facec29efbe2c7628cb68e077afc27d8c06c3613`.
- **PR head before this checkpoint update:** `3b7def57ed417a94278255357e5ad2381b917b62`. Comparison against the code/test snapshot shows the two later commits changed only `AGENT_STATE.md` and `AGENT_WORKLOG.md`; no implementation or test code changed.
- **Phase:** implementation and headless integration validated; waiting for representative local TypeScript/ESLint behavior confirmation and Product Owner acceptance.
- **Merge:** not authorized. Brian must explicitly authorize PR #87.

## Current behavior decisions

- **Native LSP:** `vim.lsp.config()` plus one explicit `vim.lsp.enable()` path; Mason-LSPConfig uses `automatic_enable = false`.
- **TypeScript:** native `ts_ls`; function-call completions and references/implementations CodeLens retained. Member-specific CodeLens parity is not guaranteed by the documented TypeScript server settings.
- **Neodev:** retained temporarily for separate issue #42; its transitional helper still imports `lspconfig.util`.
- **Formatting:** Normal-mode **Ctrl+F** directly maps to Conform's `:Format`. JS/TS selects `prettierd` when available, otherwise `prettier`, following the project's Prettier config. This does **not** run ESLint `--fix`. The LSP attach path has no competing F3 or Ctrl+Shift+F formatter mapping. ESLint's native `:LspEslintFixAll` remains a separate save-time action.
- **Diagnostics:** ESLint LSP is the only configured ESLint diagnostic producer for JS/TS; `nvim-lint` no longer runs `eslint` or `eslint_d` on JS/TS/JSX/TSX. Other filetype linters remain configured. Removing overlapping asynchronous publishers addresses a credible source of stale-looking results, but the exact reported diagnostic has not been reproduced and its root cause is not proven.
- **ESLint save fix:** native nvim-lspconfig `on_attach` is composed to preserve buffer-local `:LspEslintFixAll`; `BufWritePre` invokes it. Do not use the removed legacy `:EslintFixAll`.
- **Diagnostics UI:** inline virtual text, gutter signs, floats, and navigation remain. Bufferline owns the global `update_in_insert` setting.

## Validation

| Check | Status | Evidence |
|---|---|---|
| Native LSP ownership, server settings, Mason boundary | passed | Run [#43603153115](https://github.com/brianfiszman/dotfiles/actions/runs/43603153115), code/test SHA `facec29` |
| Conform `:Format` and direct Normal-mode Ctrl+F mapping | passed | Run #43603153115; current code path statically rechecked |
| Single JS/TS ESLint diagnostics producer | passed (configuration assertion) | Run #43603153115; no JS/TS `eslint` / `eslint_d` entries in nvim-lint |
| Native ESLint save-fix command | passed (mocked client) | Run #43603153115; asserts `LspEslintFixAll` → `workspace/executeCommand` / `eslint.applyAllFixes` on `BufWritePre` |
| Full isolated preparation, locked plugin restore/build hooks, normal headless startup and regression scenarios | passed | Run [#43603478475](https://github.com/brianfiszman/dotfiles/actions/runs/43603478475), pull_request event, exact PR head `3b7def57ed417a94278255357e5ad2381b917b62`; all job steps succeeded |
| QA | PASS (simulated) | Issue #41 acceptance criteria checked against implementation and CI evidence |
| Senior Reviewer | APPROVE (simulated) | Complete implementation diff reviewed; no blocking finding recorded. These are sequential roles performed by one assistant, not independent human reviews. |
| Real TypeScript/ESLint attachment on Brian's project | unverified | Requires local project/runtime |
| Stale diagnostic after edit → fix → undo | pending | Need identify actual diagnostic source/client and reproduce after restarting with this branch |
| Interactive macOS Ctrl+F behavior | pending | Headless test verifies mapping and command existence, not macOS editor interaction |
| PR merge / issue closure | not authorized / open | Requires Brian's acceptance and explicit merge authorization |

## Next concrete action

1. Brian updates Neovim from `feat/lsp-native-setup-41` and verifies Ctrl+F in a representative TS/JS file. Be precise that this is the existing Prettier path, not ESLint `--fix`.
2. Reproduce the stale diagnostic after an edit/undo. Capture `:lua vim.print(vim.diagnostic.get(0))` while it is visible and the relevant `:LspLog` lines; use the diagnostic source/client to distinguish ESLint LSP from another publisher before changing handlers.
3. Reassess issue #41 acceptance and merge only after Brian explicitly authorizes it.

## Scope boundaries

- #41 is the only committed functional item for Sprint 2.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and broad plugin inventory/update remain outside this PR.
- No bulk plugin update.
- PR #83 remains open/unmerged as a historical Sprint 1 planning checkpoint.

## Continuity rules

- Live GitHub PR, branch, issue, and Actions state are authoritative.
- Validate exact latest code/test HEAD and workflow event; docs-only commits may advance PR HEAD without changing tested code.
- Inspect ambiguous/failed logs and classify runner, dependency, startup, or behavioral failures.
- Keep `AGENT_WORKLOG.md` append-only.
- Specialist skills: `.agents/skills/neovim-maintenance/SKILL.md`, `.agents/skills/github-actions-validation/SKILL.md`, `.agents/skills/execution-continuity/SKILL.md`, `.agents/skills/scrum-team/SKILL.md`.
