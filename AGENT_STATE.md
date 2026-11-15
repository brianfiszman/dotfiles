# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`; update through a docs-only PR. Functional
branches must not edit this file. Keep this checkpoint at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `c40fc0f`.
- **Issue #89:** reopened after Brian reported JS/TS `S`, `o`, and `O`
  entering at column 0 after the initial implementation was merged.
- **Functional PR #95:** Draft, branch `fix/89-js-ts-indent`, current head
  `e006f7448ec337e1d1435cf7f11434ae3f5f56ca`. Test-only; no runtime change.

## Verified evidence

- Previous exact-head full integration [#43732469288](https://github.com/brianfiszman/dotfiles/actions/runs/43732469288)
  passed JS/JSX/TS/TSX, JSON, YAML, Lua, `2S`, and closed-fold controls.
- Pinned environment: Neovim 0.11.3 and nvim-treesitter
  `85168f15808d89b0222313652b9d2777eda3cb08`.
- Actual Home React component now runs as JSX and TSX; new exact-head run
  [#43733782831](https://github.com/brianfiszman/dotfiles/actions/runs/43733782831)
  is still in progress.
- Initial Home fixture run failed due to a test helper's Lua lexical scope,
  not indentation; the forward declaration is fixed in current head.
- The first Home JSX `o` reached column 8 as expected. `S`/`O` remain unverified.

## Pending

- Inspect #43733782831 on the exact current head; do not use the failed older run.
- Obtain the actual file extension, failing key/cursor line, and local Neovim version.
- Diagnose local parser/filetype/indentexpr before any runtime workaround.
- Keep PR #95 Draft. No interactive macOS verification or merge authorization.

## Next action

Review the current exact-head test log; then ask for missing local details if CI
still cannot reproduce the column-zero behavior.
