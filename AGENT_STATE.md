# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`; update through a docs-only PR. Functional
branches must not edit this file. Keep this checkpoint at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `c40fc0f`.
- **Issue #89:** reopened after Brian reported JS/TS `S`, `o`, and `O`
  entering at column 0 after the initial implementation was merged.
- **Functional PR #95:** Draft, branch `fix/89-js-ts-indent`, head
  `db4e497cd5ac283399eb2b6e660085e3feb9d034`. Test-only; no runtime change.

## Verified evidence

- Earlier exact-head full integration [#43732469288](https://github.com/brianfiszman/dotfiles/actions/runs/43732469288)
  passed JS/JSX/TS/TSX, JSON, YAML, Lua, `2S`, and closed-fold controls.
- Pinned environment: Neovim 0.11.3 and nvim-treesitter
  `85168f15808d89b0222313652b9d2777eda3cb08`.
- Home React JSX/TSX cases reached expected insert columns. Run
  [#43733782831](https://github.com/brianfiszman/dotfiles/actions/runs/43733782831)
  timed out because its terminal callback looped from TSX back to YAML; no
  Home assertion failure was recorded.
- Callback now proceeds to the closed-fold control. A watchdog is correctly
  placed before the final test invocation. Current exact-head run
  [#43735275124](https://github.com/brianfiszman/dotfiles/actions/runs/43735275124)
  is pending; discard results from superseded intermediate head `9ae8ea0`.

## Pending

- Verify #43735275124 on exact head `db4e497cd5ac283399eb2b6e660085e3feb9d034`.
- Obtain Brian's actual file extension, failing key/cursor line, and local Neovim version.
- Keep PR #95 Draft; no runtime workaround, interactive macOS verification, or merge authorization before evidence.
