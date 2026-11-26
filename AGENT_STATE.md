# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; this docs PR carries its proposed update. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`. Run #675 has cache-contract and macOS focus failures; keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `562a304722ef95f8c34de147f6bf36ec61568016`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 Agent preflight workflow #4 passed on head `5c72e8a`.
- Neovim run [#683](https://github.com/brianfiszman/dotfiles/actions/runs/45849001740) tested merge commit `2b0e26c2831a0db8705e1cfd07ab0450c902c3ea` (PR head `5c72e8a` + base `84a26a2`). Integration-decision and all fast checks passed; Linux/macOS integration jobs were skipped because the diff was exclusively allowlisted agent-process work, not passed.
- Run #681 exposed a stale test-fixture path: the production allowlist had `tests/ci/...`, but its test fixture asserted `scripts/ci/...`. Commit `c0fc9e4` fixed the fixture and rejected the nonexistent path.

## Pending

- Verify the new mandatory session-start recovery assertions and path-existence guard on the next exact PR head.
- Review the complete diff and merge #125 only when all required checks pass.
- PR #124 remains paused until #125 is integrated; do not modify it.

## Next action

- Inspect exact-head Agent preflight and Neovim fast-check runs for the session-start/path-fixture hardening.
