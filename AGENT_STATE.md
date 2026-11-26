# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint lives on `master`; this docs PR proposes the updated handoff. Keep <=40 lines.

## Current focus

- **Repository:** latest master merge is PR #121, [`84a26a2`](https://github.com/brianfiszman/dotfiles/commit/84a26a2082fb7a927276e61358fa10435b2ff6d3).
- **Issue #91:** open; Draft [PR #124](https://github.com/brianfiszman/dotfiles/pull/124), head `045ae7cf049563d86da3eef672c465a85db6d344`. Keep paused and do not modify.
- **Process:** Draft [PR #125](https://github.com/brianfiszman/dotfiles/pull/125), branch `docs/mandatory-agent-process-2026-11`. Source/work HEAD for this checkpoint: `32a2013f3a2ad022fcbaa54210b6d1cfac09de53`.

## Verified

- PR #121 merged as `84a26a2`; issue #33 closed.
- Agent preflight [run #19](https://github.com/brianfiszman/dotfiles/actions/runs/45856317957) passed on exact head `32a2013`.
- Neovim [run #697](https://github.com/brianfiszman/dotfiles/actions/runs/45856318022): fast checks, decision, Linux, and macOS plugin restore passed; macOS focus activation and the static gate failed.
- The focus script is byte-identical to master. Run #679 and its one same-SHA retry already reproduced the Launch Services/AppKit timeout; do not retry or modify that GUI helper in this PR.
- Active ruleset [Protect master — Mandatory CI](https://github.com/brianfiszman/dotfiles/rules/28175818) requires five contexts, including `Neovim integration gate`.
- PR #124 remains paused and untouched.

## Pending

- Move the static integration gate into `.github/workflows/agent-preflight.yml` and restore `neovim-headless.yml` to the exact base version.
- Test exact PR/head/base run matching, full-integration success, and the explicit process-only skip; keep unknown/mixed states fail-closed.

## Next action

- Inspect the final diff and require new exact-head preflight, Neovim decision/fast, and gate results before marking PR #125 Ready.
