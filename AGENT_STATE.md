# Agent execution state

_Last updated: 2026-11-27 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Resolve live refs on recovery.

## Current focus

- **Source master checkpoint:** `30b92cd71aefeab613f7dae63a181d3075981eb4`; docs checkpoints #131/#132/#133 are merged.
- **Active user-authorized task:** issue [#129](https://github.com/brianfiszman/dotfiles/issues/129), Draft PR [#130](https://github.com/brianfiszman/dotfiles/pull/130), branch `diagnose/macos-terminal-window-zorder-129`, HEAD `1d49ce823b758ae63956ffc04b2a53d14d46ec43`, base `30b92cd71aefeab613f7dae63a181d3075981eb4`. Scope is Linux-only per Brian; macOS/iTerm2 is deferred.
- **Older work:** issue #91 / Draft PR [#124](https://github.com/brianfiszman/dotfiles/pull/124) remains paused; do not resume while #130 is active. Linux cache-hit forced-build SIGSEGV attempts are exhausted.

## Verified

- PR #130 adds Ubuntu/Xvfb/Openbox/two-xterm real-PTY focus integration, Neovim v0.12.6 TUI callbacks, normal startup, and Python-provider integration. No macOS runner or iTerm2 install remains.
- Exact-head run [#753](https://github.com/brianfiszman/dotfiles/actions/runs/45928952289), PR HEAD `1d49ce8`, base `30b92cd`: decision and fast checks passed; isolated install, locked plugin restore/builds, native focus integration, normal startup, Python provider, and artifact upload all passed.
- Focus evidence from #753: raw observer received two native `ESC[O` and two `ESC[I` reports on `/dev/pts/0`; after restoring termios, real Neovim on that PTY received two native `FocusLost` and two `FocusGained` callbacks across two real xterm-window cycles.
- Agent preflight run [#121](https://github.com/brianfiszman/dotfiles/actions/runs/45929210229) passed process contracts and the exact-head aggregate `Neovim integration gate` in `full-integration` mode. The earlier #120 preflight read an out-of-date PR-body snapshot; the required preflight section was restored and #121 passed.

## Stop / pending

- macOS/iTerm2 coverage is explicitly deferred by Brian. Linux xterm evidence must not be presented as iTerm2 validation; do not resume the two exhausted macOS app-launch attempts (#738/#739).
- Earlier Linux readiness failures (#744/#746) were harness issues: the generated launcher had invalid shell quoting, then the real Neovim TUI waited at a hit-enter prompt. Those were corrected and the full exact-head #753 run passed; do not repeat those diagnoses.
- PR #130 remains Draft/unmerged because active ruleset `Protect master — Mandatory CI` still requires the obsolete context `macOS plugin restore and Python provider`. That context is absent from the current Linux-only PR head; the four remaining required contexts are present and pass. Available GitHub integration can read but not edit this ruleset.

## Next action

- Remove the obsolete macOS required-status context from the master ruleset in GitHub settings. Then re-fetch PR #130's exact head and required checks; mark Ready and squash-merge only once the live ruleset and all required checks are satisfied.
