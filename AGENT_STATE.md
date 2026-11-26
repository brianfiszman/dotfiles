# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; functional branches must not edit it. Keep <=40 lines.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, head `11be15eba35e5044e9ac482bab55ff9baaa9dbdd`.
  Run #668 failed Fast checks on stale cache-contract expectations; integrations
  were in progress at last inspection. #665 is historical for an older SHA.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`, latest change
  `185cb50950eb51bdcf8899a4ca3bbde8321d0306`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 adds the mandatory preflight and a CI contract test. The contract
  passed 4/4 only in a temporary fixture harness. Run #670 failed on an
  over-specific wording assertion; corrected at `185cb509`. Exact-head CI
  for the correction is pending.
- Standing merge authority applies only after acceptance, exact-head CI, final
  review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: inspect final results for run #668; do not infer success from
  queued/in-progress jobs or from older runs.
- PR #125: inspect the exact-head run after `185cb509`; keep draft until
  fast CI and diff review pass.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Verify PR #125's corrected contract on its exact head; then resume PR #124
  only from the live head and inspected CI logs.
