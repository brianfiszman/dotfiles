---
name: neovim-maintenance
description: Review, troubleshoot, and safely change this repository's Neovim configuration.
---

# Neovim maintenance skill

Use this workflow when reviewing or changing `.config/nvim`.

## 1. Understand before editing

- Read `.config/nvim/init.lua`, `.config/nvim/lua/plugins.lua`, and the specific module involved.
- Read the matching entry in `.config/nvim/lazy-lock.json` before assuming a plugin's API.
- Check the repository's minimum Neovim version and whether the API exists in that version.
- Search for other owners of the same behavior (for example: multiple linters, LSP server setup loops, scroll handlers, or completion mappings).
- Do not infer that a plugin is broken only because its API is old-looking; reproduce or verify the incompatibility first.

## 2. Explain the problem in user language

Before implementation, describe:
- The behavior the user sees.
- Why the current config produces it.
- The smallest safe change that should correct it.
- What could regress.

Issue titles should describe the function, not only the plugin. Use one issue per independently testable behavior.

## 3. Make small changes

- Prefer one concern per commit/PR.
- Preserve existing mappings and workflows unless the issue explicitly changes them.
- Keep plugin versions locked unless an upgrade is necessary and independently verified.
- Avoid introducing a new plugin when Neovim or an installed plugin already provides the capability.
- Do not remove a tool until its current responsibility and replacement are clear.

## 4. Validate

Run `bash scripts/neovim-smoke-test.sh` for configuration changes when network access and Neovim are available. It installs the config into an isolated temporary HOME, syncs lazy.nvim plugins, checks Lua syntax, and starts Neovim headlessly.

For changes to interactive behavior, also define a short manual test for the affected keymap, UI, LSP, formatter, linter, or debugger. Headless startup alone is not proof that these workflows behave correctly.

For performance work, collect a baseline and a comparable after-measurement. Do not call a change faster without numbers.

## 5. Report honestly

Summarize:
- What changed in terms the user can understand.
- Tests that actually ran and their output/result.
- What was not tested and why.
- Any remaining follow-up issue.

Never say the config is fully working based only on static inspection.
