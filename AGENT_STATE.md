# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`; update through a docs-only PR. Functional
branches must not edit this file. Keep this checkpoint at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `c40fc0f`.
- **Issue #89:** reopened after Brian reported JS/TS `S`, `o`, and `O`
  entering at column 0 after the initial implementation was merged.
- **Functional PR #95:** Draft, branch `fix/89-js-ts-indent`, head
  `68c4c00a18cfdf6a05960094f0fd9a2377b69a04`. Test-only; no runtime change.

## Verified evidence

- PR run [#43732469288](https://github.com/brianfiszman/dotfiles/actions/runs/43732469288)
  passed full isolated integration on the exact PR head above.
- Pinned environment: Neovim 0.11.3 and nvim-treesitter
  `85168f15808d89b0222313652b9d2777eda3cb08`.
- Real fixtures cover JS, JSX, TS, TSX, JSON, YAML, Lua, `2S`, and closed folds.
  React routes verified: `javascriptreact → javascript`,
  `typescriptreact → tsx`.
- Valid JS/TS/JSX/TSX cases pass in CI; Brian's local failing buffer is not
  reproduced. Mason/LSP/formatters were inspected and do not own `indentexpr`.

## Pending

- Obtain a minimal local failing snippet and local Neovim/Treesitter versions.
- Diagnose the exact parser/filetype/indentexpr path before any runtime fix.
- Keep PR #95 Draft until the user's symptom is reproduced, fixed, and validated.
- Interactive macOS verification is not performed by this remote environment.

## Next action

Ask for the smallest failing JS/TS buffer and local version output; do not change
Mason, LSP, formatters, linters, or Tree-sitter queries without reproduction.
