# Neovim Configuration Modernization

Tracking issue: [#16](https://github.com/brianfiszman/dotfiles/issues/16)

This is a thin index. GitHub issues are the canonical backlog and acceptance
record; PRs hold implementation and validation evidence. Keep one issue per
independently testable behavior.

**Reconciled:** 2026-11-24 after PR #119 merged; checked against the live open-issue state. This file lists
only currently open work. Closed/superseded issues remain in the GitHub history.

## Open — P0: safe, reproducible setup

_No open issues at this priority._

## Open — P1: predictable everyday editing

- [#33](https://github.com/brianfiszman/dotfiles/issues/33) — detect external
  file changes without repeated per-window checks.
- [#34](https://github.com/brianfiszman/dotfiles/issues/34) — avoid rebuilding
  all help tags at startup while preserving plugin help discovery and repair.
- [#36](https://github.com/brianfiszman/dotfiles/issues/36) — make the global
  `wrap` default explicit and preserve filetype-local behavior.
- [#37](https://github.com/brianfiszman/dotfiles/issues/37) — choose one
  non-duplicative linter per language.
- [#38](https://github.com/brianfiszman/dotfiles/issues/38) — eliminate
  redundant lint invocations without delaying diagnostics.
- [#39](https://github.com/brianfiszman/dotfiles/issues/39) — define one
  observable Tab/Shift-Tab priority path for snippets, completion, and fallback.
- [#69](https://github.com/brianfiszman/dotfiles/issues/69) — replace retired
  Codeium with Avante inline suggestions; native-module runtime verification
  remains blocked by the published v0.5.0 macOS asset. [PR #112](https://github.com/brianfiszman/dotfiles/pull/112)
  was closed unmerged after its proposed `avante_lib.load()` fix was confirmed
  to be a no-op; resume this test after a corrected upstream release is published.

## Open — P1: developer tooling and portability

- [#136](https://github.com/brianfiszman/dotfiles/issues/136) — provision and
  validate JavaScript/TypeScript tooling end to end: real Jest/Mocha runs through
  Neotest and real Node/Jest debugging through Mason's JS adapter, while
  preserving lazy DAP activation and removing unused test adapters.
- [#40](https://github.com/brianfiszman/dotfiles/issues/40) — pass user arguments
  through the real Node debug adapter.
- [#45](https://github.com/brianfiszman/dotfiles/issues/45) — make shell, font,
  and clipboard behavior portable across Linux and macOS.

## Open — P2: CI performance and reliability

- [#91](https://github.com/brianfiszman/dotfiles/issues/91) — first fast-check
  split merged in [PR #92](https://github.com/brianfiszman/dotfiles/pull/92);
  exact-key lazy.nvim, Mason, and Tree-sitter caches plus safe warm build hooks
  merged in [PR #124](https://github.com/brianfiszman/dotfiles/pull/124) as
  [`d60ee4a`](https://github.com/brianfiszman/dotfiles/commit/d60ee4aa82cdda18d0bde7d41951506558d03e7e).
  The LuaSnip warm-cache shutdown crash is fixed with atomic native-library
  replacement and a real finalizer regression. The Python-provider
  path-classifier regression is already implemented in PR #114. Remaining work
  is controlled end-to-end timing analysis and any separately scoped
  behavior-suite parallelization after mutable-state isolation is proven.

## Open — research and documentation

- [#107](https://github.com/brianfiszman/dotfiles/issues/107) — evidence-based
  retrospective of the active Neovim plugin stack. This is documentation and
  inventory only; it must not change runtime configuration or the lockfile.

## Recently completed

- [#32](https://github.com/brianfiszman/dotfiles/issues/32) — preserve LuaSnip
  sessions while idle; removed destructive `CursorHold` cleanup and configured
  LuaSnip region-exit events. Merged in
  [PR #119](https://github.com/brianfiszman/dotfiles/pull/119) as
  [`fcc1abe`](https://github.com/brianfiszman/dotfiles/commit/fcc1abe7959c898b304adac1acdcd85fe7fc2575).
  Exact PR head `1bd0e27c37b50381382abefef6f83f6ecc2b27d1` passed workflow
  [#45406120492](https://github.com/brianfiszman/dotfiles/actions/runs/45406120492)
  (4/4 jobs). The real Neovim 0.12.6 test covered two `CursorHold` cycles,
  Tab/Shift-Tab navigation, exit-region behavior, and an unrelated buffer.
- [#31](https://github.com/brianfiszman/dotfiles/issues/31) — lazy.nvim
  bootstrap recovery and real isolated behavior coverage, merged in
  [PR #117](https://github.com/brianfiszman/dotfiles/pull/117) as
  [`7f06b95`](https://github.com/brianfiszman/dotfiles/commit/7f06b9548dfe0f225cc8ed7707dabe5ce48accbc).
  Exact PR head `b34f6d80eaf14c4d8249e8be302d73fde167ad1c` passed workflow
  [#45268196750](https://github.com/brianfiszman/dotfiles/actions/runs/45268196750)
  (4/4 jobs, including six real bootstrap tests, 20 integration-decision tests,
  macOS restore/provider checks, and Linux fresh-install/headless behavior).
- [#35](https://github.com/brianfiszman/dotfiles/issues/35) — use one
  scroll-animation system; closed completed on 2026-11-16.
- [#66](https://github.com/brianfiszman/dotfiles/issues/66) — keep the optional
  Python provider installable and verifiable; closed completed on 2026-11-16.
- Safe installation and headless-test foundation merged in
  [PR #71](https://github.com/brianfiszman/dotfiles/pull/71) as
  [`8e721cd`](https://github.com/brianfiszman/dotfiles/commit/8e721cddee895a12367184fca1d588fbee9e1f4f).
- CI feedback optimization slice merged in PR #92 (see #91 above).
- Legacy Treesitter compatibility on Neovim 0.12 — merged in
  [PR #95](https://github.com/brianfiszman/dotfiles/pull/95) as commit
  [`f5b2a1f`](https://github.com/brianfiszman/dotfiles/commit/f5b2a1ff7d8f0277ad33e50b64e9e9f99b34186f).
  Exact PR head `e61e0cafd41443cf4082f7c12ca60177cf90597d` passed workflow
  [#43749144164](https://github.com/brianfiszman/dotfiles/actions/runs/43749144164).
- [#76](https://github.com/brianfiszman/dotfiles/issues/76) — load Telescope
  and its extensions on the first picker action, merged in PR #104 as
  [`47b55a4`](https://github.com/brianfiszman/dotfiles/commit/47b55a4e9b7cd9e68f4445a5471e18ea81566a00).
  Exact PR head passed workflow #43796931858; Chafa multimedia preview was
  unavailable in CI and was explicitly skipped.
- [#43](https://github.com/brianfiszman/dotfiles/issues/43) — parent tracking
  lazy-loading for testing, debugging, and search; closed after children #74,
  #75, and #76 were implemented, validated, and merged.
- [#89](https://github.com/brianfiszman/dotfiles/issues/89) — scope-aware
  `S`, `o`, and `O`; behavior reconfirmed on current Treesitter.
- [#44](https://github.com/brianfiszman/dotfiles/issues/44) — migrate to current
  upstream Treesitter APIs, including Mason CLI provisioning, merged in PR #102;
  issue #97 was superseded and closed.
- [#42](https://github.com/brianfiszman/dotfiles/issues/42) — replace Neodev
  with Lazydev, merged as PR #88.
- [#74](https://github.com/brianfiszman/dotfiles/issues/74) — Neotest
  lazy-loading, merged as PR #84.
- [#75](https://github.com/brianfiszman/dotfiles/issues/75) — DAP
  lazy-loading, merged as PR #77.
- [#41](https://github.com/brianfiszman/dotfiles/issues/41) — one owner per
  language server, merged as PR #87.
- [#70](https://github.com/brianfiszman/dotfiles/issues/70),
  [#72](https://github.com/brianfiszman/dotfiles/issues/72), and
  [#73](https://github.com/brianfiszman/dotfiles/issues/73) — Go lazy-loading,
  optional Go binaries, and Norg parsers, merged in PR #71.

## Current handoff

Read [`AGENT_STATE.md`](../AGENT_STATE.md) on `master` for the active branch,
PR, verified evidence, blockers, and next action. Do not infer status from this
file.

## Standards and references

- Working agreement: [`AGENTS.md`](../AGENTS.md)
- Neovim maintenance: [`neovim-maintenance`](../.agents/skills/neovim-maintenance/SKILL.md)
- Headless testing: [`neovim-headless-testing`](../.agents/skills/neovim-headless-testing/SKILL.md)
- Actions validation: [`github-actions-validation`](../.agents/skills/github-actions-validation/SKILL.md)
- Execution continuity: [`execution-continuity`](../.agents/skills/execution-continuity/SKILL.md)
- Agent memory hygiene: [`agent-memory-hygiene`](../.agents/skills/agent-memory-hygiene/SKILL.md)
- Dependency triage: [`neovim-dependency-management`](../.agents/skills/neovim-dependency-management/SKILL.md)

Testing is part of every functional issue's scope and estimate. Define observable
acceptance scenarios and the automated unit/integration/end-to-end checks before
implementation. For interactive Neovim behavior, prefer real headless tests with
the actual configuration and plugin/LSP/tool triggers; mocks and startup-only
checks are not enough. A task is done only when its behavior tests and relevant
regression suite pass on the exact change. Pure documentation-only tasks may use
diff/Markdown review only when no runtime behavior changes.
