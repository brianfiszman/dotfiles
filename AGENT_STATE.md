# Agent execution state

_Last updated: 2026-11-26 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Resolve live refs on recovery.

## Current focus

- **Source master checkpoint:** `cd47760eb99cea1ef4ff4337ef73043e487caf34`; PRs #125, #127, #126, and docs checkpoint #131 are merged.
- **Active user-authorized task:** issue [#129](https://github.com/brianfiszman/dotfiles/issues/129), Draft PR [#130](https://github.com/brianfiszman/dotfiles/pull/130), branch `diagnose/macos-terminal-window-zorder-129`, HEAD `d2e3f7f29fc706d00943b61ba4efb7c2dece2164`. Brian confirmed iTerm2 is his normal terminal.
- **Older work:** issue #91 / Draft PR [#124](https://github.com/brianfiszman/dotfiles/pull/124) remains paused; do not resume while #130 is active. Linux cache-hit forced-build SIGSEGV attempts are exhausted.

## Verified

- PR #130 run [#739](https://github.com/brianfiszman/dotfiles/actions/runs/45919647474) on the exact head: fast checks, Linux v0.12.6 cold install/headless startup, macOS plugin restore, Avante native libraries, and iTerm2 3.7.7 installation passed.
- #739 failed before creating the iTerm2 test window: first `open -a /Applications/iTerm.app` timed out after 20s; cleanup found iTerm2 running. No Neovim UIEnter/TTY, raw focus bytes, or native focus callbacks; provider step skipped. #738 stalled at the same launch phase and found orphaned `iTerm2`/`open`.
- **Local cold-launch repro:** Brian quit iTerm2, confirmed no iTerm2 process remained, then ran the exact no-`-n` `/usr/bin/open -a /Applications/iTerm.app`; it returned exit 0 in 0.06s and opened iTerm2. This proves normal cold launch works on his existing Mac installation, not first launch after a fresh cask install.
- Related but non-conclusive: [runner-images #10329](https://github.com/actions/runner-images/issues/10329) reports an `open -a` hang for an ad-hoc-signed app on macOS ARM64; maintainers mentioned TCC/OS security as possibilities, not a confirmed root cause for this task.

## Stop / pending

- #738 and #739 exhaust the two attempts for the CI iTerm2 app-launch symptom. Do not push a speculative launcher patch or rerun the same end-to-end focus job.
- **Unconfirmed hypothesis:** the fresh Homebrew Cask install's quarantine/Gatekeeper first-launch trust path, or runner-specific TCC/LaunchServices state, explains why CI differs from Brian's already-trusted local install. Homebrew documents Cask quarantine; Apple documents first-open Gatekeeper checks/approval. Neither proves this failure.
- PR #130 remains Draft; native focus acceptance criteria are untested. This is not evidence of a Neovim focus regression.

## Next action

- Obtain a targeted macOS reproduction/maintainer diagnosis of the freshly installed cask's quarantine, signature/Gatekeeper assessment, and security/LaunchServices/TCC logs before considering another CI attempt. No third full focus run.
