# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint: `master`; functional branches must not edit it. Keep <=40 lines.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; latest master merge is PR #121,
  [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124),
  branch `perf/neovim-ci-cache-91`, head `045ae7cf049563d86da3eef672c465a85db6d344`.
  Run #675: Fast checks failed on two stale cache-contract assertions; macOS
  focus integration failed; Linux integration was still running at last check.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125),
  branch `docs/mandatory-agent-process-2026-11`; source head before this checkpoint
  correction `6f3df91d1a020c3d2de9b72d7e074a1c6960d620`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed completed.
- PR #125 adds a mandatory preflight and CI contract. Exact-head run #674
  passed Linux and macOS integration but failed fast checks: whitespace wrapping
  was not normalized because the regex matched literal `\s` rather than whitespace.
- The corrected normalizer now has a dedicated newline/tab regression test;
  exact-head CI is pending.
- Standing merge authority applies only after acceptance, exact-head CI, final
  review, mergeability, and required QA gates pass. Manual gates still apply.

## Pending

- PR #124: do not resume until PR #125 is corrected and integrated. Run #675
  has known fast-check and macOS failures; Linux completion was not yet observed.
- PR #125: verify the corrected process contract on its exact final head; keep
  Draft until all required checks and final diff review pass.
- Issue #91 remains open; no cache performance improvement is claimed yet.

## Next action

- Complete and validate PR #125; only then resume #124 from its current live head.
