# Neovim Configuration Modernization

Tracking issue: [#16](https://github.com/brianfiszman/dotfiles/issues/16)

This is a thin index. GitHub issues are the canonical backlog and acceptance
record; PRs hold implementation and validation evidence. Keep one issue per
independently testable behavior.

## Open — P0: safe, reproducible setup

- [#31](https://github.com/brianfiszman/dotfiles/issues/31) — make lazy.nvim
  bootstrap failures clear; missing-Git and failed-clone paths still need tests.
- [#66](https://github.com/brianfiszman/dotfiles/issues/66) — exclude the
  committed Python virtualenv; Python provider health needs a runtime check.

## Open — P1: predictable everyday editing

- [#32](https://github.com/brianfiszman/dotfiles/issues/32) — stop unlinking
  snippets on cursor idle.
- [#33](https://github.com/brianfiszman/dotfiles/issues/33) — stop running
  `checktime` on every `BufEnter`.
- [#34](https://github.com/brianfiszman/dotfiles/issues/34) — remove full
  `helptags` generation from startup.
- [#35](https://github.com/brianfiszman/dotfiles/issues/35) — use one
  scroll-animation system.
- [#36](https://github.com/brianfiszman/dotfiles/issues/36) — choose one default
  for line wrapping.
- [#37](https://github.com/brianfiszman/dotfiles/issues/37) — one linter per
  language.
- [#38](https://github.com/brianfiszman/dotfiles/issues/38) — reduce repeated
  lint runs while typing/opening files.
- [#39](https://github.com/brianfiszman/dotfiles/issues/39) — define Tab and
  Shift-Tab once.
- [#69](https://github.com/brianfiszman/dotfiles/issues/69) — activate Codeium on
  Insert mode; empty-buffer deferral is validated, first activation is not.
- [#89](https://github.com/brianfiszman/dotfiles/issues/89) — scope-aware `S`,
  `o`, and `O`; initial implementation merged in PR
  [#93](https://github.com/brianfiszman/dotfiles/pull/93) (`e5d7fb5`), then
  reopened after a JS/TS report. Draft follow-up
  [#95](https://github.com/brianfiszman/dotfiles/pull/95) now includes the actual
  Home React component is covered as `.js`, `.jsx`, and `.tsx`; dedicated
  `.ts` cases remain. Test-only head `be848d5` passed exact-head full integration
  [#43736863275](https://github.com/brianfiszman/dotfiles/actions/runs/43736863275),
  including all nine Home `S`/`o`/`O` cases. No runtime fix until the local
  column-zero symptom is reproduced.

## Open — P1: reliable language and navigation tools

- [#40](https://github.com/brianfiszman/dotfiles/issues/40) — make Run with Args
  pass debug arguments.
- [#43](https://github.com/brianfiszman/dotfiles/issues/43) — load testing,
  debugging, and search tools only when used (parent).
- [#44](https://github.com/brianfiszman/dotfiles/issues/44) — pin the Treesitter
  API and make parser updates predictable.
- [#45](https://github.com/brianfiszman/dotfiles/issues/45) — make shell, font,
  and clipboard settings portable.
- [#76](https://github.com/brianfiszman/dotfiles/issues/76) — load Telescope on
  the first picker action.

## Recently completed

- [#91](https://github.com/brianfiszman/dotfiles/issues/91) — Neovim CI feedback
  optimization, merged as PR
  [#92](https://github.com/brianfiszman/dotfiles/pull/92) (`7857e87`).
- [#42](https://github.com/brianfiszman/dotfiles/issues/42) — replace Neodev with
  Lazydev, merged as PR [#88](https://github.com/brianfiszman/dotfiles/pull/88)
  (`9e43312`).
- [#74](https://github.com/brianfiszman/dotfiles/issues/74) — Neotest
  lazy-loading, merged as PR [#84](https://github.com/brianfiszman/dotfiles/pull/84)
  (`110c365`).
- [#75](https://github.com/brianfiszman/dotfiles/issues/75) — DAP lazy-loading,
  merged as PR [#77](https://github.com/brianfiszman/dotfiles/pull/77)
  (`b30cf6f`).
- [#41](https://github.com/brianfiszman/dotfiles/issues/41) — one owner per
  language server, merged as PR #87 (`a743684`).
- [#70](https://github.com/brianfiszman/dotfiles/issues/70),
  [#72](https://github.com/brianfiszman/dotfiles/issues/72),
  [#73](https://github.com/brianfiszman/dotfiles/issues/73) — Go lazy-loading,
  optional Go binaries, and Norg parsers, merged in PR #71 (`8e721cd`).

## Current handoff

Read [`AGENT_STATE.md`](../AGENT_STATE.md) on `master` for the active branch, PR,
verified evidence, blockers, and next action. Do not infer status from this file.

## Standards and references

- Working agreement: [`AGENTS.md`](../AGENTS.md)
- Neovim maintenance: [`neovim-maintenance`](../.agents/skills/neovim-maintenance/SKILL.md)
- Headless testing: [`neovim-headless-testing`](../.agents/skills/neovim-headless-testing/SKILL.md)
- Actions validation: [`github-actions-validation`](../.agents/skills/github-actions-validation/SKILL.md)
- Execution continuity: [`execution-continuity`](../.agents/skills/execution-continuity/SKILL.md)
- Agent memory hygiene: [`agent-memory-hygiene`](../.agents/skills/agent-memory-hygiene/SKILL.md)

Testing is part of every functional issue's scope and estimate. Define observable
acceptance scenarios and the automated unit/integration/end-to-end checks before
implementation. For interactive Neovim behavior, prefer real headless tests with
the actual configuration and plugin/LSP/tool triggers; mocks and startup-only
checks are not enough. A task is done only when its behavior tests and relevant
regression suite pass on the exact change.
