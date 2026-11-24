# Agent execution state

_Last updated: 2026-11-24 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest `master` merge is PR #117.
- **Next functional issue:** [#32](https://github.com/brianfiszman/dotfiles/issues/32),
  preserve active LuaSnip sessions while the cursor is idle (S).
- **Policy:** latest stable Neovim/upstream APIs by default; no older-version
  compatibility unless Brian explicitly requests it.

## Verified

- PR #117 merged as [`7f06b95`](https://github.com/brianfiszman/dotfiles/commit/7f06b9548dfe0f225cc8ed7707dabe5ce48accbc); issue #31 closed completed.
- Exact PR head `b34f6d80eaf14c4d8249e8be302d73fde167ad1c` passed PR workflow [#45268196750](https://github.com/brianfiszman/dotfiles/actions/runs/45268196750), 4/4 jobs: bootstrap 6/6, integration decision 20/20, macOS restore/provider, Linux clean install, restore, and headless behavior.
- Issues #35 and #66 are also closed completed; #91's broad cache/parallelism scope remains deferred.
- Brian delegated standing merge authority to the assistant after all acceptance, exact-head CI, review, and risk-based quality gates pass.

## Pending

- #32 is the next functional task; its real LuaSnip idle/jump behavior needs focused and full headless coverage.
- #33, #34, #36–#40, #45, #69, #91, and #107 remain in the live backlog; see the canonical index and issues for current detail.

## Next action

- Start #32 on a clean branch from current `master`; reproduce the active-session loss and implement only the documented behavior.
