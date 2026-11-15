# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. A branch-local copy is not
authorization to continue paused work. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`. **Base:** `master` at `7857e87`.
- **Functional PR:** [#93](https://github.com/brianfiszman/dotfiles/pull/93)
  `fix/89-scope-indent`, Draft, head `a1c58a5`, issue
  [#89](https://github.com/brianfiszman/dotfiles/issues/89). Scope-aware
  `S`/`o`/`O`, a 268-line test, and CI wiring. **No merge authorization.**
- **Docs PR:** [#94](https://github.com/brianfiszman/dotfiles/pull/94)
  `docs/agent-memory-hygiene`, Draft, evidence head `7fdd89e`. State/worklog
  budgets, skill trims, active-artifact checks. **No merge authorization.**
- **Closed predecessor:** #90, superseded; archive `archive/indented-substitute-43` (`85f1ec7`).

## Verified evidence

- #93 PR run [#43727447409](https://github.com/brianfiszman/dotfiles/actions/runs/43727447409)
  on `a1c58a5`: decision, fast checks, and integration passed; the startup log
  ran `indented-substitute` with closed-fold `o` at row 4.
- #94 run [#43727665222](https://github.com/brianfiszman/dotfiles/actions/runs/43727665222)
  on `7fdd89e`: decision, fast checks, and integration passed; skills triggered it.
- Negative control: removing the `foldclosed()` guard makes the closed-fold
  scenario fail; the guard passes. Local pinned Neovim 0.11.3 exited 0.
- #90 root cause: fixture inherited `foldmethod=syntax`; the source line was in
  a closed fold, so native `o` opened row 4 while the test expected row 3.

## Pending and not authorized

- #93 and #94 stay Draft until Brian decides. Do not mark Ready or merge.
- #89 stays open until #93 merges; interactive macOS QA remains owner work.

## Next action

Brian reviews #93, then #94. If approved, merge and verify post-merge `master`.
