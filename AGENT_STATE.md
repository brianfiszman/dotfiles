# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint lives on `master`; this docs PR proposes the updated handoff. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`. Keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `808c359fe2177ca2748313e514bc08c15868bba8`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed.
- Agent preflight run [#8](https://github.com/brianfiszman/dotfiles/actions/runs/45850456739) and Neovim run [#687](https://github.com/brianfiszman/dotfiles/actions/runs/45850456724) passed on exact HEAD `ccb1455`; Linux/macOS jobs were skipped for its process-only diff.
- Active ruleset [Protect master — Mandatory CI](https://github.com/brianfiszman/dotfiles/rules/28175818) protects the default branch and requires five GitHub Actions contexts. Replace its matrix-specific Neovim context with `Neovim integration gate`.
- PR #124 remains paused and untouched.

## Pending

- Run exact-head preflight, fast checks, Linux/macOS integration, and the stable Neovim integration gate after the workflow change.
- Update the active ruleset to require `Neovim integration gate`, retaining Agent preflight, fast checks, integration decision, and macOS provider checks.

## Next action

- Verify exact new PR head and CI results, then reconcile the canonical checkpoint after merge.
