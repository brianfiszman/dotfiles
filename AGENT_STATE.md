# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`; update through a docs-only PR. Functional
branches must not edit this file. Keep this checkpoint at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `c40fc0f`.
- **Issue #89:** reopened after Brian reported JS/TS `S`, `o`, and `O`
  entering at column 0 after the initial implementation was merged.
- **Functional PR #95:** Draft, branch `fix/89-js-ts-indent`, head
  `e0f15f727ce718ba4e68416db99b99eb3baecd9e`. Tests/workflow only; no runtime change.

## Verified evidence

- Matrix run [#43738071448](https://github.com/brianfiszman/dotfiles/actions/runs/43738071448):
  Neovim 0.11.3 full integration passed; 0.12.6 failed in JavaScript nested-block `O`
  (expected indent 4, got 0), with the same lockfile/Treesitter revision.
- Earlier matrix run [#43737557010](https://github.com/brianfiszman/dotfiles/actions/runs/43737557010)
  failed 0.12.6 at TypeScript object `O` (expected 2, got 0); 0.11.3 passed.
- 0.11.3 passed Home React `S`/`o`/`O` under `.js`, `.jsx`, `.tsx`,
  and dedicated `.ts` cases. Pinned Treesitter: `85168f15808d89b0222313652b9d2777eda3cb08`.
- Stop after two 0.12.6 failures. Root cause below the Neovim/Treesitter indent path
  is not yet isolated; do not change runtime mapping speculatively.

## Pending

- Obtain Brian's exact failing key and line/context; compare local Treesitter checkout with `lazy-lock.json`.
- Keep PRs #95 and #96 Draft; no merge authorization.
