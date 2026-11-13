# Repository working agreement

This repository contains personal dotfiles. Treat installation and local-machine
state as user data, not disposable test fixtures.

## Source of truth and execution continuity

- Treat the current repository state and GitHub as the source of truth. Conversation
  history is useful context, but it can be stale or incomplete.
- When resuming work, inspect the current branch and worktree when available, then
  review the relevant issues, open and recently closed PRs, branch heads, and changed
  files before creating or modifying artifacts.
- Read this file and the relevant skill before making changes.
- Search existing issues and PRs before creating new ones. A closed issue may
  document a previous decision; inspect it instead of assuming the work is absent.
- Do not recreate, overwrite, close, or discard work merely because it is missing
  from the current conversation context.

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
- Follow `.agents/skills/github-project-management/SKILL.md` when creating,
  updating, comparing, or closing GitHub issues and pull requests.

## Preserving work across branches and PRs

- Similar PR titles or goals do not prove that their code changes are duplicates.
- Before closing or replacing a PR, compare its base and head, merge base, commits,
  changed files, and patches against the proposed canonical PR.
- Identify changes that exist only in the PR being closed. Preserve their branch
  or deliberately port the changes after reviewing them; do not silently discard
  them or describe them as merged.
- When consolidating competing PRs, document which PR is canonical, why the other
  is being closed, and where its unique work will be handled.
- Keep the relationship between epic, functional issue, branch, commits, PR, and
  validation results traceable.

## Validation and reporting

- Run `bash -n` for changed shell scripts.
- Run the isolated headless test when changing Neovim setup, bootstrap, plugins,
  or Lua configuration.
- Distinguish shell syntax checks, static inspection, mocked harnesses, actual
  Neovim headless startup, plugin restoration, and manual macOS interaction.
  They prove different things. A mocked harness is not a real Neovim run.
- Report exactly which tests actually ran, their results, and anything that still
  needs validation on the user's Mac. Do not report a test as passing when it was
  unavailable, skipped, mocked, or merely expected to run in CI.
