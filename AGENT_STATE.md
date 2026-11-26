# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs PR. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, current head `11be15eba35e5044e9ac482bab55ff9baaa9dbdd`.
  Latest observed PR run #668 is queued on this SHA; earlier #665 is historical and failed.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`. Source head before this
  checkpoint: `000e89416387aabab9923a8a5966b9f9d69da312`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 adds the mandatory agent preflight, a process-contract test, and
  fast-CI wiring. The test passed 4/4 in a temporary fixture harness; exact
  repository CI validation remains pending.
- Brian delegated standing merge authority after acceptance, exact-head CI,
  final review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: inspect exact-head workflow #668; do not treat the cancelled #667
  or failed #665 runs on older SHAs as validation of current changes.
- PR #125: validate the final state/worklog commit on its exact PR head; keep
  draft until fast CI and diff review pass.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Inspect PR #125's exact-head checks after the checkpoint commit, then
  continue PR #124 only from its live head and exact workflow logs.
