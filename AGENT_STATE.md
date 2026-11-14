# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize native LSP ownership and make editor behavior consistent.
- **Issue:** [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41), estimate M.
- **PR:** [#87](https://github.com/brianfiszman/dotfiles/pull/87), open and unmerged.
- **Branch:** feat/lsp-native-setup-41.
- **Base:** master at c587c8854faf2e99770ca6f30a51a529a38140bb.
- **Latest implementation/test snapshot:** 3334b4b9cdf0b22de0990e4def6ff298f4a40bd0.
- **Latest changes:** Conform-only format mappings; direct Normal-mode Ctrl+F registration; JS/TS ESLint diagnostics owned solely by ESLint LSP; tests for the direct Ctrl+F map and the absence of duplicate nvim-lint ESLint processes.
- **Current exact-head validation:** pending for the latest snapshot. Prior run #43602089534 failed because an early maparg() test did not see the WhichKey-queued mapping. The mapping is now registered directly with vim.keymap.set(); see worklog correction.
- **Merge:** not authorized. Brian must explicitly authorize PR #87.

## Current behavior decisions

- Native LSP: vim.lsp.config() plus one explicit vim.lsp.enable() path; Mason-LSPConfig uses automatic_enable = false.
- TypeScript Tools replaced by native ts_ls; function-call completion and references/implementations CodeLens retained.
- Neodev remains temporarily for #42; its helper still imports lspconfig.util.
- **Canonical formatting:** Normal-mode Ctrl+F directly maps to :Format through Conform. For JS/TS it chooses prettierd when available, otherwise prettier, and follows the project's Prettier config. It is not an ESLint --fix invocation. ESLint's EslintFixAll remains on save. LSP on_attach no longer maps F3 or Ctrl+Shift+F to vim.lsp.buf.format().
- **ESLint diagnostics:** JS/TS no longer run eslint or eslint_d through nvim-lint. The ESLint LSP is the single diagnostic owner; other nvim-lint filetypes remain configured. This removes a credible source of overlapping/out-of-order results, but the screenshot alone did not prove that duplicate publishers caused the specific stale diagnostic.
- Inline diagnostic text, gutter signs, floats, and navigation remain. Bufferline retains global update_in_insert ownership.
- Brian manually confirmed completion and K hover, and said Ctrl+F appeared to produce the expected formatting. He does not recall using :TSTools* commands.

## Validation

| Gate | Status | Evidence |
|---|---|---|
| Native LSP implementation and inline diagnostics | passed | #43598472873 and #43600645750 on their respective predecessor SHAs |
| Conform command exists | passed in failed run | #43602089534 reached the map assertion; :Format command assertion had already passed |
| Duplicate JS/TS ESLint ownership removed | pending exact-head CI | Headless assertions added to tests/nvim/lsp-native-setup.lua |
| Direct Ctrl+F mapping and test | pending exact-head CI | Conform config uses vim.keymap.set() directly; maparg assertion restored |
| Current exact-head CI | pending | Resolve latest PR head and inspect run/steps/logs |
| QA and Senior Reviewer for current diff | pending | Repeat separate passes after latest exact-head CI |
| Manual stale-diagnostic check | pending | Restart Neovim, reproduce/undo in representative TS file |
| Manual Ctrl+F behavior | partial | Brian reports the existing Ctrl+F action appeared correct; confirm updated direct mapping |
| Real TS/ESLint attachment and interactive macOS behavior | unverified | Requires representative project and local editor |
| PR #87 merge | not authorized | Requires Brian's explicit approval |

QA and Senior Reviewer are separate sequential simulated passes by the assistant, not independent human reviewers. Previous passes apply to predecessor diffs only.

## Scope boundaries

- #41 is the only committed functional issue for Sprint 2.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and broad plugin inventory/update remain outside this PR.
- No bulk plugin update.
- PR #83 remains open/unmerged as a historical planning checkpoint.

## Continuity rules

- Live GitHub PR, branch, issue, and Actions state are authoritative.
- Validate the exact latest PR head and event; predecessor runs are historical evidence only.
- Inspect all ambiguous/failed logs and classify runner, dependency, startup, or behavioral failures.
- Avoid commits during active runs where practical; concurrency may cancel superseded work.
- Keep AGENT_WORKLOG.md append-only.
- Specialist skills: .agents/skills/neovim-maintenance/SKILL.md, .agents/skills/github-actions-validation/SKILL.md, .agents/skills/execution-continuity/SKILL.md, .agents/skills/scrum-team/SKILL.md.
