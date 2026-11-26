# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; functional branches must not edit it. Keep <=40 lines.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, head `11be15eba35e5044e9ac482bab55ff9baaa9dbdd`.
  Run #668 Fast checks failed on two stale cache-contract assertions; its
  integration jobs were still running at last inspection.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`; checkpoint source head
  `1b484df7a502fda6deeeb824cc13c687c2e4ae4e`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 adds the mandatory preflight and CI contract. Runs #670/#672 exposed
  brittle literal-text checks (wrong skill token, then Markdown wrapping).
  Assertions now normalize whitespace; 15/15 source contracts pass. Exact-head
  CI for this correction is pending.
- Standing merge authority applies only after acceptance, exact-head CI, final
  review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: inspect final results for run #668; do not infer success from
  queued/in-progress jobs or older runs.
- PR #125: inspect the exact-head run after the whitespace-normalization update;
  keep draft until fast CI and diff review pass.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Verify PR #125's contract on its exact head; then resume PR #124 only from
  the live head and inspected CI logs.
