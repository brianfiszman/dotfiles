# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Detailed history is in the monthly log and live PRs.

## Current focus

- **Repository master:** `e1cc50434f15e2a8b0e388928a6f94a3e54e043b`; PRs #125, #127, and #126 are merged.
- **Issue #91:** open. Functional PR [#124](https://github.com/brianfiszman/dotfiles/pull/124) is open, Draft, branch `perf/neovim-ci-cache-91`, HEAD `ff84ba7a9af554e71be7524876263de284d00c8d`.
- **Priority authorized by Brian:** finish the macOS Terminal.app focus failure in #124. The prerequisite that #125 merge first has been satisfied; do not treat its old pause note as current authorization.
- **Secondary Linux issue:** cache-hit forced-build SIGSEGV. Its two diagnostic attempts are exhausted; do not launch another speculative cache-hit CI run.

## Verified

- PR #125 merged as `c9c217b9af732eda4317d0d35ecdd4e5dbf01765`.
- PR #127 merged as `d38071fd1b0d06ba59c15d93aa48067946b88021`; `AGENTS.md` now requires proactive context compaction and `tests/ci/agent-process-contract.test.cjs` protects it.
- PR #126 merged as `e1cc50434f15e2a8b0e388928a6f94a3e54e043b`; monthly log records the #124 macOS focus evidence and Linux task-count observation.
- Neovim run [#712](https://github.com/brianfiszman/dotfiles/actions/runs/45877998509), exact PR #124 HEAD `ff84ba7...`: macOS locked plugin restore and Avante native-library checks passed; Neovim reached real Terminal.app TTY `/dev/ttys000` and `UIEnter`; Finder remained frontmost after the native click, so FocusGained and downstream Python-provider checks did not pass/run.
- Linux #711 cold restore completed 9 build tasks; #712 cache-hit restore completed 3, then forced `+Lazy! build all` completed 93 tasks before Neovim SIGSEGV. The count difference is evidence, not a proven crash cause.

## Pending

- The macOS occlusion hypothesis is unconfirmed: `open -a Finder "$test_root"` may raise a Finder folder window over the Terminal click point. Existing logs do not contain full WindowServer z-order/bounds.
- Local environment is Debian without macOS WindowServer; do not claim native macOS reproduction locally.

## Next action

- Instrument one targeted macOS diagnostic to capture the full on-screen window list immediately before the click: front-to-back order, owner/PID, ID, layer, name, bounds, and any overlap of windows above the target Terminal point.
- Keep the real Neovim TTY FocusGained/FocusLost assertions. Do not change click coordinates/event source or rerun Linux cache-hit CI before this evidence.
