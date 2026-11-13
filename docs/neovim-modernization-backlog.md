# Neovim Configuration Modernization

Tracking issue: [#16 — Neovim configuration modernization](https://github.com/brianfiszman/dotfiles/issues/16)

The backlog is organized around changes the user can observe. Keep one issue per
independently testable behavior; do not create multiple tickets for the same
underlying fix.

## P0 — Make a fresh setup safe and reproducible

- [#26 Remove the obsolete dein.vim installation step](https://github.com/brianfiszman/dotfiles/issues/26)
- [#27 Preserve existing Neovim and Emacs configs with backups](https://github.com/brianfiszman/dotfiles/issues/27)
- [#28 Keep system package installation separate from dotfiles setup](https://github.com/brianfiszman/dotfiles/issues/28)
- [#29 Make Neovim and Emacs installation choices explicit](https://github.com/brianfiszman/dotfiles/issues/29)
- [#30 Run a headless Neovim startup smoke test on every change](https://github.com/brianfiszman/dotfiles/issues/30)
- [#31 Make lazy.nvim bootstrap failures clear and actionable](https://github.com/brianfiszman/dotfiles/issues/31)
- [#66 Exclude the committed Python virtual environment from installation](https://github.com/brianfiszman/dotfiles/issues/66)

## P1 — Make everyday editing predictable

- [#32 Stop automatically unlinking snippets when the cursor is idle](https://github.com/brianfiszman/dotfiles/issues/32)
- [#33 Avoid running checktime every time a buffer window is entered](https://github.com/brianfiszman/dotfiles/issues/33)
- [#34 Remove full helptags generation from every Neovim startup](https://github.com/brianfiszman/dotfiles/issues/34)
- [#35 Use one scroll-animation system instead of three](https://github.com/brianfiszman/dotfiles/issues/35)
- [#36 Choose one intentional default for line wrapping](https://github.com/brianfiszman/dotfiles/issues/36)
- [#37 Run one chosen linter per language instead of duplicate tools](https://github.com/brianfiszman/dotfiles/issues/37)
- [#38 Reduce repeated lint runs while typing and opening files](https://github.com/brianfiszman/dotfiles/issues/38)
- [#39 Define Tab and Shift-Tab behavior only once](https://github.com/brianfiszman/dotfiles/issues/39)
- [#69 Load Codeium when entering insert mode, not when opening any buffer](https://github.com/brianfiszman/dotfiles/issues/69)
- [#70 Load Go tooling for Go files, not every command prompt](https://github.com/brianfiszman/dotfiles/issues/70)

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
- [#72 Keep optional Go helper binaries out of the default plugin installation](https://github.com/brianfiszman/dotfiles/issues/72)
- [#73 Expose installed Norg parsers on Neovim's runtimepath](https://github.com/brianfiszman/dotfiles/issues/73)

## Current handoff — 2026-11-13

Canonical implementation branch: [PR #71](https://github.com/brianfiszman/dotfiles/pull/71),
currently open, mergeable, and not merged. The latest validated code head is
`4d745c2f38bb5eb15e27f13e8fd0a34ad5eaf4c3`, with full integration run
[43501627966](https://github.com/brianfiszman/dotfiles/actions/runs/43501627966)
passing isolated preparation, locked plugin restore/build hooks, normal startup,
and the Go lazy-loading regression scenarios.

The branch received only documentation/backlog changes after the validated code
head. I compared the complete commit range: no Neovim configuration, installer,
test-script, or workflow code changed. The workflow is path-filtered away from
backlog-only updates, so run #43501627966 remains the applicable runtime result.

The final artifact [14072829773](https://github.com/brianfiszman/dotfiles/actions/runs/43501627966/artifacts/14072829773)
was inspected. It contains explicit PASS lines for the non-Go `CmdlineEnter`
path and the positive `go` and `gomod` filetype paths.

Issue state on the PR branch (not yet merged):

| Issue | Branch status | Remaining work |
|---|---|---|
| #30 | Implemented and full smoke flow passed | Keep open until PR #71 merges |
| #66 | Installer excludes the committed virtualenv; README documents a dedicated provider environment | Provider health still needs an explicit runtime check |
| #69 | Codeium loads on InsertEnter; empty-buffer startup no longer starts it | First InsertEnter activation and external language-server bootstrap are not yet verified |
| #70 | Implemented and validated in PR #71 head `4d745c2` / run #43501627966 | Keep open until PR #71 merges |
| #72 | Optional Go helper bulk install removed; restore now detects failed tool-install notifications | Keep open until PR #71 merges |
| #73 | Neorg parser dependencies and runtimepath are fixed; clean startup asserts both parsers | Keep open until PR #71 merges |
| #43 | Tracking parent for on-demand optional workflows | Children #74, #75, and #76 are planned |
| #74 | Neotest/adapters lazy-loading work defined | Not started |
| #75 | DAP/UI/adapter lazy-loading work defined | Not started; keep #40 Run with Args separate |
| #76 | Telescope/extension lazy-loading work defined | Not started |

Do not close or mark branch-implemented issues complete before PR #71 is
merged. After each subsequent commit, use the exact latest PR head SHA and its
own Actions result; run #43501627966 validates the latest executable-code snapshot
(`4d745c2`). Later commits only update documentation/backlog.

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
