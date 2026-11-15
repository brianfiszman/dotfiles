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

- Exact-head full integration [#43735275124](https://github.com/brianfiszman/dotfiles/actions/runs/43735275124)
  passed on `db4e497`: install, plugin restore, normal startup, and all
  headless behavior tests completed successfully.
- Home React passed all six `S`/`o`/`O` cases in JSX and TSX; the log
  confirms `javascriptreact → javascript` and `typescriptreact → tsx`.
- The test covers JS/TS blocks and objects, Lua, JSON, YAML, counted `2S`,
  and closed-fold behavior. Neovim 0.11.3; Treesitter lock
  `85168f15808d89b0222313652b9d2777eda3cb08`.
- User confirmed affected files include `.js` and `.ts`; JSX/TSX are
  suspected but not yet confirmed locally. The actual Home component is now
  also tested as `.js` in current functional head `be848d5`; run
  [#43736863275](https://github.com/brianfiszman/dotfiles/actions/runs/43736863275)
  is pending exact-head validation. Intermediate watchdog head `9ae8ea0` is superseded.

## Pending

- Obtain Brian's actual file extension, failing key/cursor line, and local Neovim version.
- Reproduce the local column-zero behavior before proposing runtime changes.
- Keep PR #95 Draft; no runtime workaround, interactive macOS verification, or merge authorization before evidence.
