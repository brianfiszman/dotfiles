# Agent execution state

_Last updated: 2026-11-14 (America/Argentina/Buenos_Aires)_

## Current task

- **Status:** Sprint 2 is active. Implementing [#41 — Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41) on `feat/lsp-native-setup-41`. The implementation is not yet in a PR; all runtime validation and review gates remain pending.
- **Repository:** `brianfiszman/dotfiles`
- **Base:** `master` after PR #86 merge commit `c587c8854faf2e99770ca6f30a51a529a38140bb`.
- **Implementation branch:** `feat/lsp-native-setup-41`.
- **Last inspected implementation commit before this checkpoint update:** `6b017922ca5e97975673600f9e497bba9d1bd2d3`; resolve the remote branch ref for the persisted checkpoint/worklog snapshot.
- **Issue:** [#41](https://github.com/brianfiszman/dotfiles/issues/41).
- **PR:** not opened yet.

## Sprint 2

- **Dates:** 2026-11-14 through 2026-11-20.
- **Estimate:** #41 — M.
- **Sprint Goal:** move LSP setup to one explicit native Neovim configuration and activation path per server while preserving current supported workflows.
- **Committed scope:** #41 only.
- **Not committed:** #42 (lazydev), #44 (Treesitter), #76 (Telescope), and the full remaining-plugin update audit.

## Completed and verified before this sprint

- [#75 DAP lazy-loading](https://github.com/brianfiszman/dotfiles/issues/75) merged in [PR #77](https://github.com/brianfiszman/dotfiles/pull/77), merge commit `b30cf6f87dc1a8adbd573a25c712f540db2e548a`.
- [#74 Neotest lazy-loading](https://github.com/brianfiszman/dotfiles/issues/74) merged in [PR #84](https://github.com/brianfiszman/dotfiles/pull/84), merge commit `110c3658085c4c23d847de36108b5e15e72b605`.
- Documentation PRs #85 and #86 are merged. PR #86 merge commit is `c587c8854faf2e99770ca6f30a51a529a38140bb`.
- Parent [#43](https://github.com/brianfiszman/dotfiles/issues/43) remains open. #75 and #74 are complete; #76 remains open.
- PR #83 remains open/unmerged as a historical Sprint 1 planning checkpoint. It is not part of the current implementation.

## Sprint 2 diagnosis and decisions

- The prior LSP path combined lsp-zero v3.x, Mason-LSPConfig v1-style handlers, direct legacy `require("lspconfig").setup()` calls, repeated server configuration, and special TypeScript/ESLint setup.
- Correction to the earlier audit: lsp-zero's upstream README mentions a v4 branch. Do not claim the entire project is officially dead. This migration removes the repository's v3.x orchestration in favor of native Neovim APIs.
- The exact locked TypeScript Tools revision calls the deprecated `require("lspconfig")` framework internally. The selected replacement is native `ts_ls`, with complete-function-call completion and references/implementations CodeLens retained in settings.
- Targeted dependency versions: nvim-lspconfig v2.12.0 (`4d363f93c3581b9212a24f7a830d7590b3f050af`), Mason-LSPConfig v2.3.0 (`a5671269a1ddfa7790cdf97c14e600e269da550f`), Mason v2.3.1 (`2a6940af80375532e5e9e7c1f2fc6319a1b7a69d`).
- nvim-lspconfig v2.12.0 requires Neovim 0.11.3+, so the CI baseline is now v0.11.3.
- Neodev remains for the separate #42 migration. Its compatibility helper still imports `lspconfig.util`; remove this remaining transitive legacy dependency when replacing neodev with lazydev.

## Implementation changes on the branch

- Replaced lsp-zero's plugin spec with `lsp.native`.
- Reworked `lsp/config.lua` around `vim.lsp.config()` and one per-server override table, followed by one `vim.lsp.enable(M.servers)` call.
- Configured Mason-LSPConfig with `automatic_enable=false`; Mason installs packages, explicit native config owns activation.
- Replaced TypeScript Tools with native `ts_ls`; retained completion and CodeLens settings and the previous lockfile-based workspace root policy.
- Moved nvim-cmp's Tab/Shift-Tab behavior to local LuaSnip mappings instead of lsp-zero helpers; retained cmp-nvim-lsp setup and hover/signature float borders.
- Updated Mason repository namespace in the DAP spec.
- Updated only the LSP dependency lock entries and removed lsp-zero/TypeScript Tools lock entries; no repository-wide update.
- Raised CI Neovim from v0.11.0 to v0.11.3.
- Added `tests/nvim/lsp-native-setup.lua` and wired it into `scripts/test-nvim-headless.sh`.

## Validation

| Check | Status | Evidence |
|---|---|---|
| Static review of upstream API/version requirements | passed | Selected releases and requirements inspected; see issue #41 and work log |
| Real plugin restore | pending | Must run on PR head |
| Normal real Neovim headless startup | pending | Must run on PR head |
| Native LSP behavior assertions | pending | New test file wired into CI; not run yet |
| QA | pending | Separate QA pass required |
| Senior Reviewer | pending | Separate full-diff review required |
| PR #41 merge | not authorized | Requires Brian's explicit authorization for this PR |

## Blockers / known limitations

- No real Neovim runtime or plugin restore has yet run for this branch.
- Neodev's `before_init` helper still imports `lspconfig.util`; #42 owns removing that transitive compatibility path.
- Headless tests can assert configuration and activation wiring, but representative project attachment, TypeScript/ESLint save behavior, and interactive macOS behavior still need manual validation.

## Next concrete action

Inspect the full branch diff and test harness, open the PR linked to #41, then run the full isolated workflow on the exact PR head. Record QA and Senior Reviewer as separate simulated role passes. Do not merge without Brian's separate explicit authorization.
