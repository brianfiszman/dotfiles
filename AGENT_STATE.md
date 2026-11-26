# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; this docs PR carries its proposed update. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`. Run #675 has cache-contract and macOS focus failures; keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `c0fc9e4ee02e7db870a82ad3811d425a71674229`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 Agent preflight workflow #2 passed for source head `241ec0e131c778221bda4064ab3b184ce0a3880d`.
- Neovim run [#681](https://github.com/brianfiszman/dotfiles/actions/runs/45847862939) tested merge commit `8438b9d94923c4013326e646320b5c591a5c6bae` (PR head `241ec0e` + base `84a26a2`). Integration-decision passed; fast checks failed 22/23 because the classifier test fixture used `scripts/ci/...` instead of the real `tests/ci/...` path. Linux/macOS integration jobs were skipped, not passed.
- Commit `c0fc9e4` corrects the fixture and explicitly rejects the nonexistent `scripts/ci/...` path.

## Pending

- Re-fetch PR #125 head; verify fresh Agent preflight and Neovim fast checks on that exact head. Run #681 is historical for the newer commit.
- Review the complete diff and merge #125 only when every required check passes.
- PR #124 remains paused until #125 is integrated; do not modify it.

## Next action

- Inspect exact-head Actions runs after `c0fc9e4`; diagnose any new failure from its full log before another change.
