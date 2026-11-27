# Agent execution state

_Last updated: 2026-11-27 (America/Argentina/Buenos_Aires)_

Canonical checkpoint on `master`; keep <=40 lines. Resolve live refs on recovery.

## Current focus

- **Source master checkpoint:** `d60ee4aa82cdda18d0bde7d41951506558d03e7e`.
- **Active implementation:** none. Brian asked to resume PR #124; it is complete and merged. Do not reopen it.
- **Issue [#91](https://github.com/brianfiszman/dotfiles/issues/91):** remains open for controlled end-to-end timing analysis and any separately scoped behavior-suite parallelization after mutable-state isolation is proven. These broader tasks were not part of merged PR #124; do not claim an end-to-end speedup.
- **PR [#124](https://github.com/brianfiszman/dotfiles/pull/124):** merged as [`d60ee4a`](https://github.com/brianfiszman/dotfiles/commit/d60ee4aa82cdda18d0bde7d41951506558d03e7e).
- **PR [#130](https://github.com/brianfiszman/dotfiles/pull/130):** merged as [`86986ba`](https://github.com/brianfiszman/dotfiles/commit/86986ba893ea53cb49e5b09f3af5d14b516981b2). Its accepted scope is Linux-native xterm/PTY focus; macOS/iTerm2 behavior remains deferred and unvalidated.

## Verified

- PR #124 exact head `f5732aebd5b268d41bc5ce751b349e1675e27962` passed Neovim integration [#772](https://github.com/brianfiszman/dotfiles/actions/runs/45999208336) and agent preflight/integration gate [#151](https://github.com/brianfiszman/dotfiles/actions/runs/46000159902).
- Lazy.nvim, Mason, and Tree-sitter exact-key caches were validated across cold and warm runs. Cache hits still run locked restore and serialized configured build hooks; scheduled/manual paths remain cold; fork PRs cannot read/write trusted caches.
- Warm-cache SIGSEGV root cause: LuaSnip's upstream build overwrote `luasnip-jsregexp.so` in place while loaded. The production hook now uses same-directory temp copy + atomic rename; a real Neovim `package.loadlib()` finalizer regression passes. See [incident fingerprint](docs/incidents/ci-failure-fingerprints.md).
- Earlier all-hit diagnostic [#767](https://github.com/brianfiszman/dotfiles/actions/runs/45941847788) ended normally under GDB with no SIGSEGV. Final exact-head run #772 passed the full Linux behavior/provider suite.
- QA PASS and simulated Senior Reviewer APPROVE are recorded in PR #124. GitHub disallows formal self-approval by the connected PR author; this limitation is documented, not represented as an actual GitHub APPROVED state.

## Next action

- No implementation is currently authorized. Keep issue #91 open; refine the remaining timing/parallelization scope before starting another work slice.
- On recovery, consult `AGENTS.md`, this checkpoint, the current monthly log, incident fingerprints, and live GitHub state before acting.
