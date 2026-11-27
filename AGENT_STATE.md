# Agent execution state

_Last updated: 2026-11-27 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Resolve live refs on recovery.

## Current focus

- **Source master checkpoint:** `2c497ad25fa2fcb56ff8ae91093f05430069e2dc`; PRs #125, #127, #126, and docs checkpoints #131/#132 are merged.
- **Active user-authorized task:** issue [#129](https://github.com/brianfiszman/dotfiles/issues/129), Draft PR [#130](https://github.com/brianfiszman/dotfiles/pull/130), branch `diagnose/macos-terminal-window-zorder-129`, HEAD `f909677ce4666507413e3208eaeb16c68338ab16`. Brian explicitly redirected this task to Linux-only validation; macOS/iTerm2 testing is deferred.
- **Older work:** issue #91 / Draft PR [#124](https://github.com/brianfiszman/dotfiles/pull/124) remains paused; do not resume while #130 is active. Linux cache-hit forced-build SIGSEGV attempts are exhausted.

## Verified

- PR #130 now runs Ubuntu-only integration: Xvfb/Openbox, two xterm windows, a raw real-PTY observer, Neovim v0.12.6, normal startup, and the Python provider check. No macOS runner or iTerm2 install remains.
- Local Xvfb/xterm smoke emitted native `ESC[O`/`ESC[I` on `/dev/pts/0`; the temporary local harness used a stand-in reader, not real Neovim callbacks.
- Run [#744](https://github.com/brianfiszman/dotfiles/actions/runs/45925511060), head `707a08baa0553820cbb773923d96553a65e1b761`: plugin restore passed; raw xterm focus reports arrived twice in each direction; target xterm exited before Neovim readiness. Xterm logs reported a missing `-misc-fixed` font.
- Run [#745](https://github.com/brianfiszman/dotfiles/actions/runs/45925997120), head `f98d0281ddd730808a2f0d6a0e4a393d3c5b1512`, was cancelled during plugin restore before the focus step.
- Run [#746](https://github.com/brianfiszman/dotfiles/actions/runs/45926099975), exact head `f909677ce4666507413e3208eaeb16c68338ab16`: X11 packages including `xfonts-base` and plugin restore passed; raw xterm emitted two native loss and two gain reports; target xterm again exited before Neovim readiness. No Neovim startuptime/verbose logs or native callbacks were produced; normal startup and provider steps were skipped.
- On #746, fast checks, integration decision, and Agent preflight process-contract tests passed; the exact-head integration gate failed because the Linux focus job failed.

## Stop / pending

- #744 and #746 are the two actual attempts for the Linux target-xterm-before-Neovim-readiness symptom. The two-attempt limit is exhausted; do not run a third full E2E or push speculative fixes.
- **Root cause unknown:** after the raw observer restores termios, the shell reports that it is execing Neovim, then the target xterm exits before readiness. The artifact has no child startup/verbose log, so it does not distinguish an exec failure, immediate Neovim exit, or early startup crash.
- macOS/iTerm2 validation is explicitly deferred per Brian's direction. Linux xterm evidence must not be presented as iTerm2 coverage.
- PR #130 remains Draft and issue #129 remains open. Neovim-native FocusLost/FocusGained callbacks are unverified; this is not evidence of a Neovim regression.

## Next action

- Diagnose the child-process boundary separately from the full focus E2E: capture the `exec` result, child exit status, and Neovim stderr/startup logs in an isolated launch reproduction. Decide on a code change only after that evidence; no third full focus run without a new, independently supported hypothesis.
