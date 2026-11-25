# Agent execution state

_Last updated: 2026-11-25 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest merge is PR #120, commit
  [`a9fe7da`](https://github.com/brianfiszman/dotfiles/commit/a9fe7daaf89e8dfc43f4ab8425d7a267ea3563fa).
- **Issue #33:** Draft [PR #121](https://github.com/brianfiszman/dotfiles/pull/121),
  branch `fix/checktime-focus-33`, head `e7b94594844ae152b5c917ff0e17cc4b10e1b393`.
- **Policy:** latest stable Neovim/upstream APIs by default; no older-version
  compatibility unless Brian explicitly requests it.

## Verified

- PR #117 merged as [`7f06b95`](https://github.com/brianfiszman/dotfiles/commit/7f06b9548dfe0f225cc8ed7707dabe5ce48accbc); issue #31 closed.
- PR #119 merged as [`fcc1abe`](https://github.com/brianfiszman/dotfiles/commit/fcc1abe7959c898b304adac1acdcd85fe7fc2575); issue #32 closed.
- PR #120 merged as [`a9fe7da`](https://github.com/brianfiszman/dotfiles/commit/a9fe7daaf89e8dfc43f4ab8425d7a267ea3563fa); PR #113 superseded.
- PR #121 removes only the unconditional `BufWinEnter :checktime` callback; Neovim 0.12.6 performs native timestamp checks on UI FocusGained.
- Exact PR #121 head passed workflow [#45530863126](https://github.com/brianfiszman/dotfiles/actions/runs/45530863126), 4/4 jobs. The focused native-focus regression passed in 9 seconds.
- Brian delegated standing merge authority after acceptance, exact-head CI, final review, mergeability, and required QA gates pass. This does not bypass manual checks.

## Pending

- PR #121 remains draft. Real macOS terminal focus-loss/focus-gain and unsaved-conflict behavior is not yet manually verified; do not merge before it passes.
- #34, #36–#40, #45, #69, #91, and #107 remain in the live backlog; see the canonical index and issues.

## Next action

- Perform the three-step physical-terminal check documented in PR #121. Then recheck the exact diff and mark Ready/merge only if it passes.
