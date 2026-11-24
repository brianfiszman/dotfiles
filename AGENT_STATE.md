# Agent execution state

_Last updated: 2026-11-24 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest merge is PR #119
  ([`fcc1abe`](https://github.com/brianfiszman/dotfiles/commit/fcc1abe7959c898b304adac1acdcd85fe7fc2575)).
- **Next functional issue:** [#33](https://github.com/brianfiszman/dotfiles/issues/33),
  avoid repeated per-window `:checktime` while detecting external file changes.
- **Policy:** latest stable Neovim/upstream APIs; no legacy compatibility by default.

## Verified

- PR #119 merged; issue #32 closed completed.
- Exact PR head `1bd0e27c37b50381382abefef6f83f6ecc2b27d1` passed workflow
  [#45406120492](https://github.com/brianfiszman/dotfiles/actions/runs/45406120492),
  4/4 jobs. The real LuaSnip test passed two 4s CursorHold cycles, Tab/Shift-Tab,
  region exit, and unrelated-buffer behavior.
- PR #117/#31 also completed; exact-head workflow #45268196750 passed 4/4.
- Brian delegated standing merge authority once acceptance, exact-head CI,
  diff review, mergeability, and risk-based gates pass; no per-PR approval needed.

## Pending

- #33 needs FocusGained/external-change automation, no-repeat window checks,
  unsaved-buffer safety, and the documented manual macOS focus validation.
- #34, #36–#40, #45, #69, #91, and #107 remain open; #91's broad cache/parallelism
  scope stays deferred pending safety evidence.

## Next action

- Refine #33, preserving its real FocusGained path and manual macOS validation
  requirement; then implement and test only its documented scope.
