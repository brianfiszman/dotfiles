# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Resolve live refs on recovery.

## Current focus

- **Source master checkpoint:** `8b944176307bf3022a26f19cb46cea89eaac38f9`; PRs #125, #127, and #126 are merged.
- **Active user-authorized task:** issue [#129](https://github.com/brianfiszman/dotfiles/issues/129), Draft PR [#130](https://github.com/brianfiszman/dotfiles/pull/130), branch `diagnose/macos-terminal-window-zorder-129`, HEAD `d2e3f7f29fc706d00943b61ba4efb7c2dece2164`. Brian confirmed his normal terminal is iTerm2.
- **Older work:** issue #91 / Draft PR [#124](https://github.com/brianfiszman/dotfiles/pull/124) remains paused; do not resume while #130 is active. Linux cache-hit forced-build SIGSEGV attempts are exhausted.

## Verified

- PR #130 run [#739](https://github.com/brianfiszman/dotfiles/actions/runs/45919647474) on the exact head: fast checks and Linux v0.12.6 cold install/headless startup passed. macOS plugin restore and Avante native libraries passed; iTerm2 3.7.7 installed with bundle ID `com.googlecode.iterm2`.
- #739 failed before creating the dedicated iTerm2 test window: initial `open -a /Applications/iTerm.app` exceeded 20 seconds and exited 124. Runner cleanup found the spawned iTerm2 process. No Neovim UIEnter/TTY, raw focus bytes, or native focus callbacks were observed; provider step skipped.
- Previous run [#738](https://github.com/brianfiszman/dotfiles/actions/runs/45918882843) stalled silently in the same step for 6m49s; supersession cleanup found orphaned `iTerm2` and `open` processes.
- Agent run [#93](https://github.com/brianfiszman/dotfiles/actions/runs/45919674468): process-contract checks passed; exact-head integration gate failed because #739 failed.

## Stop / pending

- #738 and #739 exhaust the two-attempt limit for the iTerm2 app-launch symptom. Why `open` remains blocked after spawning iTerm2 is unknown. This is not evidence of an iTerm2 focus-report failure or a Neovim focus regression.
- PR #130 remains Draft and must not merge. Native focus acceptance criteria remain untested.

## Next action

- Isolate macOS LaunchServices / `open -a` startup independently, or obtain a targeted macOS reproduction, before resuming the end-to-end focus test. No third speculative helper patch or same-symptom CI rerun.
