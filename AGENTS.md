# Working on these dotfiles

This repository is a personal workstation configuration. Changes should make everyday workflows more reliable, not just make the config look cleaner.

## How to describe work

Write issues and pull requests in functional language first:
- What will the user notice?
- What currently happens?
- What should happen instead?
- How will we prove it works?

Avoid unexplained plugin names and internal implementation details in titles. Include file paths and plugin/API names in the technical section when useful.

Keep one user-visible problem per issue. Split unrelated fixes into separate issues. Group related tasks under an epic only when they are genuinely one workstream.

## How to change the config

- Preserve existing workflows and keymaps unless a change explicitly replaces them.
- Prefer small, reviewable changes over large rewrites.
- Do not update every plugin as a shortcut for fixing one broken plugin.
- Check the locked plugin revision and the installed Neovim API before changing configuration.
- Do not silently add machine-specific paths, credentials, generated environments, or OS assumptions.
- Installation scripts must not delete active user data or run privileged package-manager commands.
- Back up user files before replacing them and provide a dry-run mode for setup changes.

## Validation

For Neovim changes:
1. Run shell syntax checks for shell scripts.
2. Run the isolated headless smoke test when available.
3. Check actual plugin setup and language-server behavior for changes that cannot be covered by headless startup.
4. State clearly which checks ran and which remain manual.

A passing headless startup does not prove that keybindings, UI rendering, clipboard, language servers, formatters, debuggers, or typing latency work on every machine.

## Reporting

Every change summary must say:
- What changed, in user-visible terms.
- Which tests were run and their result.
- Any remaining risk or manual test.
- The issue(s) addressed.

Do not claim a performance improvement without a before/after measurement.
