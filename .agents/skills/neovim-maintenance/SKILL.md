---
name: neovim-maintenance
description: Maintain and improve this repository's Neovim configuration safely, with functional issues, incremental changes, and reproducible headless checks.
---

# Neovim maintenance

## Goal

Improve the actual editing experience without turning the configuration into a
minimal demo or breaking useful workflows. Optimize for predictable startup,
responsive editing, reliable language tooling, and a setup that can be reproduced
on another machine.

## How to work with the maintainer

- Communicate directly and explain the user-visible effect of each technical
  change. Avoid unexplained plugin jargon.
- Prefer a small number of clearly scoped fixes over a sweeping rewrite.
- Explain trade-offs when removing, replacing, or delaying a plugin.
- Be explicit about evidence: a static observation is not a measured performance
  result, and a headless test is not a replacement for testing the Mac UI.
- Never request or use a personal access token when the connected GitHub
  integration is sufficient.

## Issue quality

Create one issue for each independently testable behavior. A good issue contains:

1. **What you notice** — describe the current behavior in plain language.
2. **Desired behavior** — describe what should happen from the user's perspective.
3. **Scope** — list the configuration area or files likely involved.
4. **Acceptance criteria** — concrete checks that prove the behavior changed.
5. **Validation** — say whether the check is static, headless, or requires manual
   interaction.

Avoid tickets such as "clean up Neovim". Prefer a ticket like "Opening a file
should not start the AI completion plugin until the user enters Insert mode".

Before creating an issue, search the repository's open issues and reuse or
update an existing ticket instead of creating a duplicate.

## Safe installation rules

- The installer must never call `sudo`, `apt`, `pacman`, or another system
  package manager.
- The default install target is Neovim only. Emacs is opt-in.
- Existing targets are moved to unique, timestamped backups before replacement.
- Stage files before swapping them into place; attempt to restore the backup if
  the final move fails.
- Exclude `.config/nvim/venv` from installation. A virtualenv is generated for
  one machine and must never be copied to another.
- Keep dry-run behavior available and side-effect free.

## Neovim test strategy

Run checks in this order when applicable:

1. **Shell syntax:** `bash -n install.sh scripts/test-nvim-headless.sh`.
2. **Isolated installation:** run the installer with a temporary HOME and XDG
   directories. Never test by pointing it at the maintainer's real home.
3. **Plugin restore:** use `:Lazy! restore` to install the versions recorded in
   `lazy-lock.json`, rather than silently upgrading everything.
4. **Headless startup:** launch the installed configuration again and fail on
   Lua/plugin startup errors.
5. **Interactive macOS check:** validate terminal rendering, font, clipboard,
   keymaps, LSP attachment, completion, and perceived typing latency on the
   maintainer's Mac.

The automated test is intended to prove that a clean checkout can install and
start in a Linux environment. It cannot prove how the configuration feels in a
terminal on macOS.

## Plugin and LSP changes

- Keep plugin specifications explicit; one top-level plugin entry per repository.
- Keep lazy loading tied to actual use: filetype for language tooling, commands
  or keys for search/debug/test workflows, and insert mode for typing assistants.
- Avoid overlapping providers for scrolling, formatting, linting, highlighting,
  and LSP server setup.
- Preserve `lazy-lock.json` unless a ticket explicitly includes a plugin version
  change.
- Pin or document APIs when upstream plugins make breaking branch migrations.
- Verify optional executables before invoking external linters or formatters.
- Make missing tools produce actionable messages rather than repeated noise.

## Completion criteria

A fix is complete only when:

- Its acceptance criteria pass.
- Relevant automated checks pass, or the reason they cannot run is documented.
- The README/backlog is updated when behavior or setup instructions change.
- The user is told what changed and what remains unverified.
