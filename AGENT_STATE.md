# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; this docs PR carries its proposed update. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`. Run #675 has cache-contract and macOS focus failures; keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `1c252c23ef4d1fc6a61ef10f3c37caf299e6188c`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- Agent preflight [run #7](https://github.com/brianfiszman/dotfiles/actions/runs/45849873033) passed on PR head `1c252c2`.
- Neovim run [#686](https://github.com/brianfiszman/dotfiles/actions/runs/45849873011) passed integration-decision and all fast checks, including classifier/path-existence and bootstrap tests. Linux/macOS integration jobs were skipped because this diff was exclusively agent-process work; they are not claimed as passed.
- The session-start rule now requires canonical master state, monthly log, and live GitHub recovery for every new repository conversation. The classifier test verifies allowlist paths exist.

## Pending

- Live GitHub configuration shows `master` is unprotected and repository rulesets are empty; required CI checks are therefore not confirmed as merge-blocking.
- Configure required status checks for Agent preflight, fast checks, and applicable runtime integration before treating this as a hard merge gate.
- Review and integrate #125 after that protection is configured and exact-head checks pass. PR #124 remains paused.

## Next action

- Configure/verify the `master` ruleset, then re-fetch the current PR head and checks before Ready/merge.
