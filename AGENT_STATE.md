# Agent execution state

_Last updated: 2026-11-24 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest `master` merge is PR #117.
- **Active functional issue:** [#32](https://github.com/brianfiszman/dotfiles/issues/32),
  implemented in Draft [PR #119](https://github.com/brianfiszman/dotfiles/pull/119),
  branch `fix/luasnip-idle-session-32`, head `4d0ca7be41557c1a405aeb01e1e8a866e0c1849c`.
- **Policy:** latest stable Neovim/upstream APIs by default; no older-version
  compatibility unless Brian explicitly requests it.

## Verified

- PR #117 merged as [`7f06b95`](https://github.com/brianfiszman/dotfiles/commit/7f06b9548dfe0f225cc8ed7707dabe5ce48accbc); issue #31 closed completed.
- Exact PR head `b34f6d80eaf14c4d8249e8be302d73fde167ad1c` passed PR workflow [#45268196750](https://github.com/brianfiszman/dotfiles/actions/runs/45268196750), 4/4 jobs: bootstrap 6/6, integration decision 20/20, macOS restore/provider, Linux clean install, restore, and headless behavior.
- Issues #35 and #66 are also closed completed; #91's broad cache/parallelism scope remains deferred.
- Brian delegated standing merge authority to the assistant after all acceptance, exact-head CI, review, and risk-based quality gates pass.

## Pending

- #32 implementation and exact-head validation are in progress. Workflow [#45400421041](https://github.com/brianfiszman/dotfiles/actions/runs/45400421041) is running; no behavior is yet marked validated.
- #33, #34, #36–#40, #45, #69, #91, and #107 remain in the live backlog; see the canonical index and issues for current detail.

## Next action

- Finish reviewing PR #119's Linux/macOS headless results, correct any failures, then mark Ready and merge only when all acceptance and quality gates pass.
