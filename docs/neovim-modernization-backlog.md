# Neovim Configuration Modernization

Tracking issue: [#16 — Neovim configuration modernization](https://github.com/brianfiszman/dotfiles/issues/16)

The backlog is organized around changes the user can observe. Keep one issue per
independently testable behavior; do not create multiple tickets for the same
underlying fix.

## P0 — Make a fresh setup safe and reproducible

- [#31 Make lazy.nvim bootstrap failures clear and actionable](https://github.com/brianfiszman/dotfiles/issues/31) — success path is covered; missing-Git and failed-clone error paths still need focused tests.
- [#66 Exclude the committed Python virtual environment from installation](https://github.com/brianfiszman/dotfiles/issues/66) — installer exclusion is merged; Python provider health still needs a real runtime check.

## P1 — Make everyday editing predictable

- [#32 Stop automatically unlinking snippets when the cursor is idle](https://github.com/brianfiszman/dotfiles/issues/32)
- [#33 Avoid running checktime every time a buffer window is entered](https://github.com/brianfiszman/dotfiles/issues/33)
- [#34 Remove full helptags generation from every Neovim startup](https://github.com/brianfiszman/dotfiles/issues/34)
- [#35 Use one scroll-animation system instead of three](https://github.com/brianfiszman/dotfiles/issues/35)
- [#36 Choose one intentional default for line wrapping](https://github.com/brianfiszman/dotfiles/issues/36)
- [#37 Run one chosen linter per language instead of duplicate tools](https://github.com/brianfiszman/dotfiles/issues/37)
- [#38 Reduce repeated lint runs while typing and opening files](https://github.com/brianfiszman/dotfiles/issues/38)
- [#39 Define Tab and Shift-Tab behavior only once](https://github.com/brianfiszman/dotfiles/issues/39)
- [#69 Load Codeium when entering insert mode, not when opening any buffer](https://github.com/brianfiszman/dotfiles/issues/69) — empty-buffer deferral is validated; the first InsertEnter activation remains unverified.

## P1 — Keep language and navigation tools reliable

- [#40 Make the Run with Args keymap actually pass debug arguments](https://github.com/brianfiszman/dotfiles/issues/40)
- [#41 Give every language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/41)
- [#42 Replace the archived neodev plugin with lazydev](https://github.com/brianfiszman/dotfiles/issues/42)
- [#43 Load testing, debugging, and search tools only when used (tracking parent)](https://github.com/brianfiszman/dotfiles/issues/43)
- [#74 Load Neotest and its adapters only when a test action is invoked](https://github.com/brianfiszman/dotfiles/issues/74)
- [#75 Load DAP, its UI, and debug adapters only when debugging is invoked](https://github.com/brianfiszman/dotfiles/issues/75)
- [#76 Load Telescope and its extensions on the first picker action](https://github.com/brianfiszman/dotfiles/issues/76)
- [#44 Pin the Treesitter API and make parser updates predictable](https://github.com/brianfiszman/dotfiles/issues/44)
- [#45 Make shell, font, and clipboard settings portable](https://github.com/brianfiszman/dotfiles/issues/45)


## Completed — PR #71 merged on 2026-11-13

[PR #71](https://github.com/brianfiszman/dotfiles/pull/71) was squash-merged
into `master` as [`8e721cd`](https://github.com/brianfiszman/dotfiles/commit/8e721cddee895a12367184fca1d588fbee9e1f4f).

The runtime code head `f1273d8cab4b3c0aec090abee20e22cd45fce2f5` passed
[Actions run #43504068345](https://github.com/brianfiszman/dotfiles/actions/runs/43504068345):
isolated installer preparation, locked plugin restore/build hooks, normal headless
startup, and behavioral checks for Go's `CmdlineEnter`, `go`, and `gomod`
triggers. The artifact was uploaded successfully.

Completed issues:
- [#26](https://github.com/brianfiszman/dotfiles/issues/26) — remove obsolete dein.vim setup.
- [#27](https://github.com/brianfiszman/dotfiles/issues/27) — preserve existing configs with backups.
- [#28](https://github.com/brianfiszman/dotfiles/issues/28) — keep OS package installation out of the dotfiles installer.
- [#29](https://github.com/brianfiszman/dotfiles/issues/29) — make Neovim/Emacs install modes explicit.
- [#30](https://github.com/brianfiszman/dotfiles/issues/30) — clean isolated install and headless smoke test.
- [#70](https://github.com/brianfiszman/dotfiles/issues/70) — load Go tooling only for Go filetypes.
- [#72](https://github.com/brianfiszman/dotfiles/issues/72) — keep optional Go binaries out of default restore.
- [#73](https://github.com/brianfiszman/dotfiles/issues/73) — make Norg parsers discoverable and loadable.

Still open after the merge:
- [#31](https://github.com/brianfiszman/dotfiles/issues/31) — test missing-Git and failed-clone bootstrap paths.
- [#34](https://github.com/brianfiszman/dotfiles/issues/34) — verify help tags remain discoverable after a clean install.
- [#66](https://github.com/brianfiszman/dotfiles/issues/66) — verify the Python provider in a real Neovim runtime.
- [#69](https://github.com/brianfiszman/dotfiles/issues/69) — verify the first InsertEnter activation and Codeium startup.

## Current handoff — next functional PR

The next target is [#75 — DAP lazy-loading](https://github.com/brianfiszman/dotfiles/issues/75),
the prerequisite for [#74 — Neotest lazy-loading](https://github.com/brianfiszman/dotfiles/issues/74).
[Telescope #76](https://github.com/brianfiszman/dotfiles/issues/76) stays separate
and follows after these.

An existing branch, `feat/dap-on-demand`, contains eight commits beyond the
validated #71 code head. Its exclusive diff is limited to the DAP configuration
files, the Neotest-to-DAP dependency/mapping, and the headless test script.
The branch predates the squash merge in its ancestry, so do not open a PR from
it directly or port the old #71 history again.

The final branch commit introduced doubled shell escape characters in
`scripts/test-nvim-headless.sh` (including line continuations). Treat this as
a harness defect to repair, not as validated DAP work. Preserve the original
branch and review/port its DAP-only changes onto a clean branch based on the
new `master`. Then validate #75 before starting #74.

**Working cadence:** one functional PR at a time. Finish implementation, inspect
the full diff, validate the exact PR head, merge it, close only its completed
issues, reconcile this backlog, and only then start the next PR. Keep unrelated
or dependent work on separate branches/issues; do not mix them into the PR being
closed.

## Working agreement

- Each ticket describes a visible problem, desired behavior, scope, and acceptance
  criteria.
- Preserve current workflows and keymaps unless the issue explicitly changes them.
- Do not mass-update plugins as part of an unrelated fix.
- Measure startup before and after; do not claim a speedup without measurements.
- Separate Linux headless results from macOS interactive validation.
- Use `AGENTS.md` and [the Neovim maintenance skill](../.agents/skills/neovim-maintenance/SKILL.md)
  as the repository's working agreement.
- Use the [GitHub Actions validation skill](../.agents/skills/github-actions-validation/SKILL.md)
  to trace workflow runs by exact commit and event.
