# Repository working agreement

This repository contains personal dotfiles. Treat installation and local-machine
state as user data, not disposable test fixtures.

## Safety rules

- Never run the installer against a real home directory during tests.
- Use `scripts/test-nvim-headless.sh`, which redirects HOME and all XDG paths
  into a temporary directory.
- Do not delete or overwrite existing editor configuration without creating a
  recoverable, timestamped backup.
- Do not install OS packages from the dotfiles installer. System dependencies
  must be explicit and documented separately.
- Do not commit credentials, API tokens, local virtual environments, caches,
  compiled binaries, or machine-specific absolute paths.
- Do not run a bulk plugin update as part of an unrelated fix.

## Change workflow

- Work on a topic branch; keep the default branch untouched until a reviewed PR
  is merged.
- Prefer one independently testable behavior per issue and small reviewable
  changes.
- Write issues in user-visible terms: what currently happens, what should happen,
  and how we will know it is fixed.
- Preserve existing keymaps and workflows unless a ticket explicitly changes
  them.
- Update the README when setup or user-facing behavior changes.
- Keep the functional backlog in `docs/neovim-modernization-backlog.md`.
- Follow `.agents/skills/neovim-maintenance/SKILL.md` for Neovim-specific work.

## Validation and reporting

- Run `bash -n` for changed shell scripts.
- Run the isolated headless test when changing Neovim setup, bootstrap, plugins,
  or Lua configuration.
- Distinguish syntax checks, headless startup checks, plugin restore checks,
  and manual macOS interaction checks. They prove different things.
- Report exactly which tests ran, their results, and anything that still needs
  validation on the user's Mac.
