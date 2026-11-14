# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Sprint:** Sprint 2, 2026-11-14 through 2026-11-20. Goal: modernize the LSP foundation using one native Neovim setup/activation path per server while preserving supported workflows.
- **Issue:** [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41), estimate M.
- **PR:** [#87](https://github.com/brianfiszman/dotfiles/pull/87), open and unmerged.
- **Branch:** `feat/lsp-native-setup-41`.
- **Base:** `master` at `c587c8854faf2e99770ca6f30a51a529a38140bb`.
- **Current implementation head:** `dd801182126c65a01123c65daf72a43220243e22`.
- **Exact-head validation:** [Actions run #43600006360](https://github.com/brianfiszman/dotfiles/actions/runs/43600006360) is in progress for the current head. Do not claim it passed until it completes.
- **Merge:** not authorized. Brian must explicitly authorize PR #87 after all required gates.

## Current implementation and manual feedback

- Replaced lsp-zero orchestration and legacy direct lspconfig setup with native `vim.lsp.config()` and one explicit `vim.lsp.enable()` activation path.
- Mason-LSPConfig uses `automatic_enable = false`; server overrides are centralized and each server is configured once.
- Replaced TypeScript Tools with native `ts_ls`; preserved function-call completions, references/implementations CodeLens, and lockfile-based workspace root behavior.
- Moved nvim-cmp Tab/Shift-Tab behavior off lsp-zero while preserving LuaSnip behavior.
- Updated only the LSP-related dependency versions and removed lsp-zero/TypeScript Tools lock entries. Neovim minimum/CI baseline is 0.11.3.
- Neodev remains temporarily for #42; its `before_init` helper still imports `lspconfig.util`. Remove that transitional dependency in the separate lazydev migration.
- Preserved keymaps: `K` hover, `F3` format buffer/selection, `Ctrl-Shift-F` synchronous format, `<leader>DF` diagnostic float, `[d` / `]d` diagnostic navigation, and `<leader>D` Telescope diagnostics.
- Brian manually confirmed that completion works and `K` shows symbol information. He also reported that diagnostic signs appeared without the error text being visible; this was traced to `virtual_text = false`.
- In response, current head `dd801182` changes diagnostics to `virtual_text = { spacing = 2, source = "if_many" }`, so diagnostic messages should display inline without a keypress. The headless assertion was updated to require a virtual-text table. This exact change is not yet validated by the in-progress run.
- Brian does not recall using any proprietary `:TSTools*` commands. The repository has no mapped/configured use of them; native `ts_ls` migration proceeds without preserving those commands.
- Manual F3 formatting and the new always-visible inline diagnostic presentation still need Brian's validation after the branch is installed. Real-project TS/ESLint attachment and interactive macOS behavior also remain outside headless CI.

## Validation status

| Gate | Status | Evidence |
|---|---|---|
| Previous code head runtime validation | passed | Run [#43598472873](https://github.com/brianfiszman/dotfiles/actions/runs/43598472873), successful on predecessor head `131b8c3831dc2dfce243bc611c3dfe992fec8b0a` |
| Current head runtime validation | in progress | Run [#43600006360](https://github.com/brianfiszman/dotfiles/actions/runs/43600006360), exact head `dd801182126c65a01123c65daf72a43220243e22` |
| Earlier QA pass | passed on predecessor | QA reviewed issue #41 acceptance criteria before the inline-diagnostic preference change; repeat against final exact head |
| Earlier Senior Reviewer pass | approved predecessor | Separate simulated pass before the inline-diagnostic preference change; repeat against final complete diff |
| Manual completion and hover | passed | Brian's report |
| Manual formatting and inline diagnostics | pending | Await validation of F3 and inline messages |
| PR #87 merge | not authorized | Requires Brian's explicit authorization |

The QA and Senior Reviewer roles are separate sequential simulated passes by the assistant, not independent human reviewers.

## Sprint scope boundaries

- #41 is the only committed functional issue for this sprint.
- #42 (lazydev), #44 (Treesitter), #76 (Telescope), and the broader dependency inventory/update remain outside this PR.
- Do not perform an indiscriminate bulk plugin update.
- PR #83 remains open/unmerged as a historical planning checkpoint.

## Continuity and validation rules

- Treat live GitHub PR, branch, commit, and Actions state as authoritative; verify this checkpoint before resuming.
- For every runtime change, validate the exact PR head, not a predecessor SHA.
- Inspect all jobs/steps and logs; a pending job is not a hang, and an in-progress run is neither pass nor failure.
- Avoid commits while a run is active; workflow concurrency can cancel the superseded run.
- Keep QA and Senior Reviewer passes separate. Never merge without explicit authorization for this PR.
- Keep `AGENT_WORKLOG.md` append-only. Skills:
  - `.agents/skills/neovim-maintenance/SKILL.md`
  - `.agents/skills/github-actions-validation/SKILL.md`
  - `.agents/skills/execution-continuity/SKILL.md`
