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
  branch `docs/mandatory-agent-process-2026-11`; source head before this checkpoint
  update `d95578dda3d2b24af3028bb3a9c89fc6c4d73671`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 run #676 passed all fast checks (5/5 process tests) and Linux
  fresh-install/headless startup; macOS was queued when this head was superseded.
- Run #677 correctly rejected the synchronize-event payload because the PR body
  preflight section was added after that event. The current PR body now includes it.
- Standing merge authority applies only after acceptance, exact-head CI, final
  review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: do not resume until PR #125 is integrated. Run #675 has known fast
  cache-contract and macOS focus failures; Linux completion was not observed.
- PR #125: verify the current body through a new synchronize event, then pass
  the validator, process tests, and all integration jobs before review/merge.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Validate PR #125's new exact head; then resume #124 from its live head.
