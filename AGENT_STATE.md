# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; this docs PR carries its proposed update. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`. Run #675 has cache-contract and macOS focus failures; keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `b5ae80d2d4eeb3e9ec55a5b8fd04b6a4bac8bce8`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- Agent preflight [run #6](https://github.com/brianfiszman/dotfiles/actions/runs/45849549196) passed PR-body validation on `b5ae80d` but failed one process-contract assertion: its regex over-escaped the dot in `AGENT_STATE.md`. The policy text itself was present.
- Neovim run [#685](https://github.com/brianfiszman/dotfiles/actions/runs/45849549186) on `b5ae80d` passed integration-decision and all fast checks; Linux/macOS jobs were skipped by the process-only classifier, not passed.
- The fix uses literal `includes()` rather than a regex for the checkpoint filename; run it on the new exact head.

## Pending

- Verify the literal session-start contract, path-existence guard, and PR preflight on one exact final head.
- Review the complete diff and merge #125 only when all required checks pass.
- PR #124 remains paused until #125 is integrated; do not modify it.

## Next action

- Inspect exact-head Agent preflight and Neovim fast-check runs after the literal assertion fix.
