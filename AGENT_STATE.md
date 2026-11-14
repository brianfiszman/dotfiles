# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize LSP setup using one native Neovim configuration/activation path per server, with consistent editing behavior.
- **Issue:** [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41), estimate M.
- **PR:** [#87](https://github.com/brianfiszman/dotfiles/pull/87), open and unmerged.
- **Branch:** feat/lsp-native-setup-41.
- **Base:** master at c587c8854faf2e99770ca6f30a51a529a38140bb.
- **Implementation snapshot before this checkpoint/work-log update:** 1b8bfbf87bec7e36582fff131a280be0f8d35b3e.
- **Latest code/test changes:** Conform-only formatting path; single ESLint diagnostic owner for JS/TS; headless assertions for both; README editing guidance.
- **Latest exact-head CI observed before checkpoint update:** [run #43602089534](https://github.com/brianfiszman/dotfiles/actions/runs/43602089534) was in progress for implementation snapshot 1b8bfbf87bec7e36582fff131a280be0f8d35b3e. Its result must not be reused for any later SHA.
- **Merge:** not authorized. Brian must explicitly authorize PR #87.

## Current behavior decisions

- Native LSP: vim.lsp.config() + one explicit vim.lsp.enable() path; Mason-LSPConfig uses automatic_enable = false.
- TypeScript Tools replaced by native ts_ls; completion and references/implementations CodeLens remain configured.
- Neodev remains temporarily for #42; its compatibility helper still imports lspconfig.util.
- **Canonical formatting:** Normal-mode Ctrl+F invokes Conform's :Format command. For JS/TS Conform chooses prettierd when available, otherwise prettier, and follows the project's Prettier configuration. This is not the same thing as invoking ESLint --fix; the ESLint LSP still runs EslintFixAll before saving an attached buffer. LSP on_attach no longer registers F3 or Ctrl+Shift+F mappings that call vim.lsp.buf.format().
- **Diagnostic ownership:** screenshot showed an inline message labelled eslint: Parsing error: ',' expected. The repository had ESLint diagnostics configured in both the ESLint LSP and nvim-lint, which also launched both eslint and eslint_d on JS/TS BufReadPost, BufWritePost, and InsertLeave. This is a credible source of overlapping/out-of-order diagnostics, but the exact origin of Brian's one reported stale message is not proven by the screenshot alone. Removed nvim-lint ESLint entries for JS, TS, JSX, and TSX; the ESLint LSP is the sole JS/TS ESLint diagnostic publisher. Other nvim-lint filetypes remain unchanged.
- Existing inline diagnostic text, gutter signs, floats, and navigation remain. Bufferline retains ownership of global update_in_insert.
- Brian manually confirmed completion and K hover. He prefers Ctrl+F formatting and reported it appeared to follow the expected project formatting. He does not recall using :TSTools* commands; no compatibility shim is planned.

## Validation

| Gate | Status | Evidence |
|---|---|---|
| Previous native LSP implementation | passed | Run #43598472873 on predecessor SHA 131b8c3 |
| Inline diagnostic display | passed | Run #43600645750 on exact code/test SHA 380e35d |
| Conform mapping + no duplicate ESLint linters | pending | Added assertions to tests/nvim/lsp-native-setup.lua; run #43602089534 was in progress on source SHA 1b8bfbf before checkpoint/worklog commits |
| Current exact-head Actions run | pending | Resolve branch's latest HEAD after docs commits; inspect all steps/logs |
| QA for current complete diff | pending | Repeat after final exact-head CI |
| Senior Reviewer for current complete diff | pending | Separate final-diff review required |
| Manual stale-diagnostic check | pending | Restart Neovim with update, reproduce/undo in representative TS file |
| Manual formatter behavior | partial | Ctrl+F already worked by Brian's report; confirm it remains the single path on updated config |
| Real project TS/ESLint attachment and interactive macOS behavior | unverified | Headless CI cannot fully reproduce them |
| PR #87 merge | not authorized | Requires Brian's explicit approval |

QA and Senior Reviewer are separate sequential simulated passes by the assistant, not independent human reviewers. Earlier passes applied to predecessor diffs and do not count for the current follow-up changes.

## Scope boundaries

- #41 is the only committed functional issue for Sprint 2.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and broad dependency inventory/update remain outside this PR.
- No indiscriminate bulk plugin update.
- PR #83 remains open/unmerged as a historical planning checkpoint.

## Continuity rules

- Treat live GitHub PR, branch, commit, issue, and Actions state as authoritative.
- Validate the exact current PR head and correct event; predecessor runs are historical evidence only.
- Inspect failed or ambiguous job logs and distinguish runner, dependency restore, startup, and behavioral failures.
- Avoid commits during active Actions runs when possible; concurrency may cancel superseded runs.
- Keep AGENT_WORKLOG.md append-only.
- Specialist skills: .agents/skills/neovim-maintenance/SKILL.md, .agents/skills/github-actions-validation/SKILL.md, .agents/skills/execution-continuity/SKILL.md, .agents/skills/scrum-team/SKILL.md.
