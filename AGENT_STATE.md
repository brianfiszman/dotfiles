# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; functional branches must not edit it. Keep <=40 lines.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`.
  Run #675: cache-contract fast checks and macOS focus integration failed.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`; source head before this update
  `9c22f7ba06f8cbb0e7fcc011e277498784aa7071`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- Dedicated agent workflow #1 passed on `9c22f7b`.
- Neovim run #680 fast tests exposed classifier-fixture issues: wrong
  allowlist path, outdated no-baseline compare expectations, and omitted
  macOS focus-script integration classification. Heavy runtime jobs were
  correctly required because the decision test path was not allowlisted.
- PR #679's unchanged master macOS focus test timed out twice; the same script
  passed in #674. No GUI fix or pass is claimed.

## Pending

- PR #124 remains paused until PR #125 is integrated; its run #675 has known
  cache-contract and macOS focus failures. Do not modify #124 yet.
- PR #125: rerun fast classifier tests, confirm the strict process-only skip,
  and verify dedicated preflight workflow on the exact final head.
- Issue #91 remains open; no cache performance improvement is claimed.

## Next action

- Validate and integrate PR #125, then recover #124 from its live branch head.
