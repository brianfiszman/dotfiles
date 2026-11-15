# Agent execution state

_Last updated: 2026-11-15 (America/Argentina/Buenos_Aires)_

Canonical copy lives on `master`. Functional branches must not edit this file;
state updates land through a dedicated docs change. Keep this file at 40 lines or fewer.

## Current focus

- **Repository:** `brianfiszman/dotfiles`; PR #100 is merged.
- **Merge:** [PR #100](https://github.com/brianfiszman/dotfiles/pull/100),
  commit `d48b73fe874b20a6d4bfd9aba2e976f1af748f2e`; issue #99 is closed.
- **Policy:** target latest stable Neovim/plugin APIs; no older-version
  compatibility by default. See the Neovim maintenance skill.

## Verified evidence

- PR #100 exact head `e8ebac969ba0c22a27563ef11e96e36ff9284453` passed
  [workflow #43763594502](https://github.com/brianfiszman/dotfiles/actions/runs/43763594502):
  all four jobs, including isolated Neovim 0.11.3 and 0.12.6 coverage.
- Latest stable Neovim is 0.12.6. The current `nvim-treesitter` `main`
  branch is a breaking rewrite requiring Neovim 0.12+, `tree-sitter-cli`
  0.26.1+, and a C compiler.
- No local Mac installation or plugin checkout was changed by the assistant.

## Pending

- Issue #44: migrate from frozen legacy Treesitter API to current upstream API;
  reassess and absorb the CLI work in #97.
- Issue #89: verify its JS/TS indentation behavior against the current supported
  Treesitter API; do not preserve a legacy branch just for older Neovim.
- Issue #66: optional Python provider provisioning remains separate.

## Next action

- Inspect every currently used Treesitter feature and design a tested migration
  to upstream `main` on latest stable Neovim. Keep only latest stable in CI.
