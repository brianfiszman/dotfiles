# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; functional branches must not edit it. Keep <=40 lines.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`.
  Run #675: fast cache-contract checks and macOS focus integration failed;
  Linux was still running at last observation.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`; checkpoint source head
  `3debd3ffee8e5a8dc2515e24f6d6a176fc628f1b`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 run #678: preflight validator passed; process contract was 7/8.
  One negative test expected the path error, but input `none` correctly hit the
  earlier placeholder rule. The fixture is being corrected, not the validator.
- Run #676 passed fast checks and Linux startup; macOS was queued on its head.
- Standing merge authority applies only after acceptance, exact-head CI, final
  review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: do not resume until PR #125 is integrated. Run #675 has known fast
  cache-contract and macOS focus failures; Linux completion was not observed.
- PR #125: rerun the separated negative cases, then require the validator, all
  process tests, and full Linux/macOS integration on one exact head.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Validate PR #125's corrected exact head; then resume #124 from its live head.
