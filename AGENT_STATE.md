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
  `292e13cce27d04a0133fe85d4bb04659f6686215`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 run #679 attempt 1 and retry attempt 2: preflight/fast checks and
  Linux startup passed. The unchanged master macOS focus script timed out twice
  during Terminal.app reactivation; same script passed in #674. No fix or
  pass is claimed for that unrelated GUI behavior.
- Process-only CI is being separated into `agent-preflight.yml`; the Neovim
  classifier will skip heavy runtime integration only for an exact allowlist.
- Standing merge authority applies only after acceptance, exact-head checks,
  final review, mergeability, and required QA gates pass.

## Pending

- PR #124 remains paused until PR #125 is integrated; its run #675 still has
  known cache-contract and macOS focus failures. Do not modify #124 yet.
- PR #125: validate the dedicated preflight workflow, process tests, main
  fast checks, and fail-closed path-classifier tests on the exact final head.
- Issue #91 remains open; no cache performance improvement is claimed.

## Next action

- Finish and integrate PR #125, then recover #124 from its live branch head.
