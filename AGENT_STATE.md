# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`; update through a docs-only PR. Functional
branches must not edit this file. Keep this checkpoint at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `c40fc0f`.
- **Issue #89:** reopened after Brian reported JS/TS `S`, `o`, and `O`
  entering at column 0 after the initial implementation was merged.
- **Functional PR #95:** Draft, branch `fix/89-js-ts-indent`, head
  `be848d54895a1d0022c83c5c12bd14b106b7171c`. Test-only; no runtime change.

## Verified evidence

- Exact-head full integration [#43736863275](https://github.com/brianfiszman/dotfiles/actions/runs/43736863275)
  passed on `be848d5`: install, plugin restore, normal startup, all headless tests.
- Actual Home React source passed `S`, `o`, and `O` as `.js`, `.jsx`,
  and `.tsx`; JS route is `javascript → javascript`, React route
  `javascriptreact → javascript`, TSX route `typescriptreact → tsx`.
- Dedicated `.ts` interface and object fixtures passed with parser
  `typescript`. Neovim 0.11.3; Treesitter lock
  `85168f15808d89b0222313652b9d2777eda3cb08`.
- Remaining gap: exact local key/cursor context and local Neovim version to
  reproduce Brian's column-zero report. No runtime change made.

## Pending

- Obtain the failing key (`S`, `o`, or `O`), cursor line/context, and local Neovim version.
- Reproduce locally before any runtime workaround.
- Keep both PRs Draft; no merge authorization.
