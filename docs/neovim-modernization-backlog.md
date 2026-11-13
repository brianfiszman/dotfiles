# Neovim Configuration Modernization

Tracking issue: [#16 — Neovim configuration modernization](https://github.com/brianfiszman/dotfiles/issues/16)

This backlog is intentionally incremental. Preserve existing workflows, measure before/after, and avoid mass plugin updates before compatibility migrations.

## Priority order

1. **P0 — LSP migration:** [#17](https://github.com/brianfiszman/dotfiles/issues/17) — Replace lsp-zero/neodev and legacy server setup with a single native LSP configuration.
2. **P0 — Lazy loading:** [#18](https://github.com/brianfiszman/dotfiles/issues/18) — Make tests, debugging, Telescope, and command-driven plugins load on demand; record startup baselines.
3. **P1 — Linting:** [#19](https://github.com/brianfiszman/dotfiles/issues/19) — Remove duplicate linters and redundant autocmd triggers.
4. **P1 — Treesitter:** [#20](https://github.com/brianfiszman/dotfiles/issues/20) — Verify API/branch compatibility, reduce parser scope, and remove overlapping features.
5. **P1 — Completion:** [#21](https://github.com/brianfiszman/dotfiles/issues/21) — Consolidate nvim-cmp mappings and snippet behavior.
6. **P1 — Editing UX/autocmds:** [#22](https://github.com/brianfiszman/dotfiles/issues/22) — Remove competing scroll animations and audit frequent autocmds.
7. **P1 — Startup cleanup:** [#24](https://github.com/brianfiszman/dotfiles/issues/24) — Remove unconditional helptags generation and repeated startup work.
8. **P2 — DAP:** [#25](https://github.com/brianfiszman/dotfiles/issues/25) — Fix undefined run-arguments callback and lazy-load debug tooling.
9. **P2 — Repository hygiene:** [#23](https://github.com/brianfiszman/dotfiles/issues/23) — Stop tracking the generated Python virtualenv and document recreation.

## Definition of done

- Existing daily editing workflows and keymaps continue to work.
- Each plugin/server/linter has one clear owner and initialization path.
- Startup and representative editing workflows are measured before and after.
- No machine-specific generated environments or secrets are committed.
- Changes land in small, reviewable commits or PRs; no broad rewrite without validation.

## Notes

- The issue tracker is the source of truth for task discussion and completion.
- This file is a repository-local index of the backlog.
- Do not upgrade Treesitter across incompatible branch/API changes without migrating its config.
