# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint lives on `master`; this docs PR proposes the updated handoff. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), head `045ae7cf049563d86da3eef672c465a85db6d344`. Keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Checkpoint source/work HEAD: `78384b115f9793792eab2f811f914da546130975`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed.
- Agent preflight [run #19](https://github.com/brianfiszman/dotfiles/actions/runs/45856317957) passed on `32a2013`.
- Neovim [run #697](https://github.com/brianfiszman/dotfiles/actions/runs/45856318022) reproduced the previously known macOS Terminal focus timeout. The GUI script is byte-identical to master; run #679 and its one same-SHA retry already exhausted the two-attempt rule.
- Neovim [run #698](https://github.com/brianfiszman/dotfiles/actions/runs/45861182539) passed on exact head `78384b1`: fast checks and decision passed; Linux and macOS runtime jobs were both skipped by the process-only classifier.
- Agent workflow push run [#20](https://github.com/brianfiszman/dotfiles/actions/runs/45861174948) failed before creating jobs because `integration-gate` was placed at YAML root rather than under `jobs:`. The gate indentation is corrected in the next commit and covered by a raw-YAML regression.
- Active ruleset [Protect master — Mandatory CI](https://github.com/brianfiszman/dotfiles/rules/28175818) is active, strict, and requires the five expected contexts, including `Neovim integration gate`.
- PR #124 remains paused and untouched.

## Pending

- Validate the corrected Agent workflow YAML, exact-head gate polling, process contracts, and the new gate unit tests.
- Inspect new pull-request event runs for the final SHA, verify both required workflows/check contexts, and review the complete diff before marking PR #125 Ready.

## Next action

- Keep PR #125 Draft until the exact final-head preflight, Neovim decision/fast checks, `Neovim integration gate`, ruleset, and full review all pass.
