# Agent execution state

_Last updated: 2026-11-24 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest merge is PR #119, commit
  [`fcc1abe`](https://github.com/brianfiszman/dotfiles/commit/fcc1abe7959c898b304adac1acdcd85fe7fc2575).
- **Next functional issue:** [#33](https://github.com/brianfiszman/dotfiles/issues/33),
  avoid redundant `:checktime` calls on every `BufWinEnter` (S).
- **Policy:** latest stable Neovim/upstream APIs by default; no older-version
  compatibility unless Brian explicitly requests it.

## Verified

- PR #117 merged as [`7f06b95`](https://github.com/brianfiszman/dotfiles/commit/7f06b9548dfe0f225cc8ed7707dabe5ce48accbc); issue #31 closed.
- PR #119 merged as [`fcc1abe`](https://github.com/brianfiszman/dotfiles/commit/fcc1abe7959c898b304adac1acdcd85fe7fc2575); issue #32 closed.
- Exact PR #119 head `1bd0e27c37b50381382abefef6f83f6ecc2b27d1` passed workflow [#45406120492](https://github.com/brianfiszman/dotfiles/actions/runs/45406120492), 4/4 jobs; the real LuaSnip idle/navigation test passed on Neovim 0.12.6.
- Issues #35 and #66 are also closed; #91's broad cache/parallelism scope remains deferred.
- Brian delegated standing merge authority to the assistant after all acceptance, exact-head CI, review, and risk-based quality gates pass.

## Pending

- #33 is the next functional task; preserve external-file detection while eliminating repeated per-window `:checktime` calls.
- #34, #36–#40, #45, #69, #91, and #107 remain in the live backlog; see the canonical index and issues for current detail.

## Next action

- Start #33 on a clean branch from current `master`; reproduce the repeated checks, add the real focus-event regression test, and record the required macOS manual validation steps.
