# Incident — closed PR #67 recovery (2026-11-13)

PR #67 (`chore/neovim-setup-and-ci`) was closed in favor of PR #71. The branch
was preserved, but its unique runtime changes were not all carried forward. The
recovery audit produced the rules below.

## What was ported

- The Neovim 0.11 version guard.
- Removal of unconditional `helptags ALL`, plus a manual repair instruction in
  the README.

## What was deliberately rejected

- CI-only mutations of plugin specs, plugin config callbacks, native build
  hooks, and Treesitter parser updates. They weakened the test by skipping real
  build behavior. PR #71 instead restores locked plugins and starts the normal
  configuration with no CI-only plugin mutations.
- A grouped lazy.nvim spec rewrite, because inspection of the locked lazy.nvim
  revision proved the existing grouped form was valid. Issue #68 was closed as
  not planned.
- An optional installer convenience flag (`--sync-plugins`), because first
  launch already installs plugins and no separate user requirement existed.

## Ticket dispositions

Older tickets #46–#65 were duplicates or superseded by canonical issues
#26–#45, not completed work. Issue #66 remained open for Python provider runtime
validation.

## Rules

- Compare the complete per-file patch of the closed PR with the canonical branch.
  Overlapping filenames or similar descriptions do not prove completeness.
- Classify every unique change explicitly: port, track separately, investigate,
  reject with evidence, or already covered.
- Never close a competing PR until every unique file-level change and every
  ticket it introduced has an explicit disposition.
- Preserving a branch does not mean its changes were accepted.
