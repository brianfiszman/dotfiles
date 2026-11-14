# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize native LSP ownership and make editor behavior consistent.
- **Issue:** [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41), estimate M.
- **PR:** [#87](https://github.com/brianfiszman/dotfiles/pull/87), open and unmerged.
- **Branch:** feat/lsp-native-setup-41.
- **Base:** master at c587c8854faf2e99770ca6f30a51a529a38140bb.
- **Latest implementation/test head:** facec29efbe2c7628cb68e077afc27d8c06c3613.
- **Exact-head CI:** [run #43603153115](https://github.com/brianfiszman/dotfiles/actions/runs/43603153115) completed successfully on the exact implementation/test head.
- **Merge:** not authorized. Brian must explicitly authorize PR #87.

## Current behavior decisions

- Native LSP: vim.lsp.config() plus one explicit vim.lsp.enable() path; Mason-LSPConfig uses automatic_enable = false.
- TypeScript Tools replaced by native ts_ls; function-call completion and references/implementations CodeLens retained.
- Neodev remains temporarily for #42; its helper still imports lspconfig.util.
- **Canonical formatting:** Normal-mode Ctrl+F directly maps to Conform's :Format. JS/TS chooses prettierd when available, otherwise prettier, following the project's Prettier configuration. This is not an ESLint --fix invocation. ESLint's native LspEslintFixAll runs before save on an ESLint-attached buffer. LSP on_attach no longer maps F3 or Ctrl+Shift+F to vim.lsp.buf.format().
- **Diagnostic ownership:** JS/TS no longer run eslint or eslint_d through nvim-lint. The ESLint LSP is the single diagnostic owner; other nvim-lint filetypes remain configured. This removes a credible source of overlapping/out-of-order results, but the screenshot alone did not prove that duplicate publishers caused the specific stale diagnostic.
- **ESLint save fix:** nvim-lspconfig v2.12.0's native ESLint on_attach creates the buffer-local :LspEslintFixAll command. The custom attach wrapper now composes that native callback and registers BufWritePre to invoke it. Do not use the removed legacy :EslintFixAll command.
- Inline diagnostic text, gutter signs, floats, and navigation remain. Bufferline retains global update_in_insert ownership.
- Brian manually confirmed completion and K hover, and said Ctrl+F appeared to produce the expected formatting. He does not recall using :TSTools* commands.

## Validation

| Gate | Status | Evidence |
|---|---|---|
| Native LSP ownership, server settings, Mason boundary | passed | Run #43603153115, exact head facec29 |
| Inline diagnostic display | passed | Run #43603153115 |
| Conform :Format + direct Ctrl+F mapping | passed | Run #43603153115 |
| Single JS/TS ESLint diagnostics publisher | passed | Run #43603153115; nvim-lint has no eslint/eslint_d JS/TS filetype entries |
| Native ESLint save-fix path | passed | Run #43603153115; stub client verifies LspEslintFixAll -> workspace/executeCommand / eslint.applyAllFixes on BufWritePre |
| Full plugin restore and normal Neovim startup | passed | Run #43603153115 |
| Neotest, Go, DAP regressions | passed | Run #43603153115 |
| QA | PASS | Complete issue #41 acceptance criteria and final PR diff reviewed |
| Senior Reviewer | APPROVE | Separate complete-diff review; no blocking findings |
| Manual stale-diagnostic check | pending | Brian to restart Neovim and reproduce/undo in a representative TS file |
| Manual Ctrl+F behavior | partial | Existing Ctrl+F worked for Brian; direct updated mapping is headless-tested; confirm on local editor |
| Real TS/ESLint attachment and interactive macOS behavior | unverified | Requires representative project and local editor |
| PR #87 merge | not authorized | Requires Brian's explicit approval |

QA and Senior Reviewer are separate sequential simulated passes by the assistant, not independent human reviewers.

## Scope boundaries

- #41 is the only committed functional issue for Sprint 2.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and broad plugin inventory/update remain outside this PR.
- No bulk plugin update.
- PR #83 remains open/unmerged as a historical planning checkpoint.

## Continuity rules

- Live GitHub PR, branch, issue, and Actions state are authoritative.
- Validate the exact latest PR code/test head and event; predecessor runs are historical evidence only.
- Inspect all ambiguous/failed logs and classify runner, dependency, startup, or behavioral failures.
- Avoid commits during active runs where practical; concurrency may cancel superseded work.
- Keep AGENT_WORKLOG.md append-only.
- Specialist skills: .agents/skills/neovim-maintenance/SKILL.md, .agents/skills/github-actions-validation/SKILL.md, .agents/skills/execution-continuity/SKILL.md, .agents/skills/scrum-team/SKILL.md.
