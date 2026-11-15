# ADR 0001 — Scope-aware indentation for `S`, `o`, and `O`

- **Status:** Proposed — accepted when [#93](https://github.com/brianfiszman/dotfiles/pull/93) merges
- **Date:** 2026-11-15
- **Issues:** [#89](https://github.com/brianfiszman/dotfiles/issues/89), [#90](https://github.com/brianfiszman/dotfiles/pull/90)

## Context

Issue #89 asks that `S`, `o`, and `O` open the new line at the indentation of
the current scope instead of column 0. The original attempt (PR #90) grew to 83
commits, added a 228-line `InsertEnter`/`startinsert!` lifecycle, and shipped a
727-line probe notebook. Its CI failed because the TypeScript fixture inherited
`foldmethod=syntax`: the source line was inside a closed fold, so native `o`
opened at row 4 while the test expected row 3. The editor behavior was not
regressed; the fixture was wrong.

## Decision

Use a small mapping layer in `.config/nvim/lua/core/general.lua`:

1. Reindent the consumed source line with `normal! ==` from Lua.
2. Replay the native `S`, `o`, or `O` through `nvim_feedkeys` with the `n` flag
   so the replay cannot recursively trigger the mapping.

Skip reindentation when the source line is inside a closed fold
(`foldclosed(line) ~= -1`) so the native fold-boundary behavior is preserved.

`:normal` / `:normal!` was rejected because it does not run the full open-line
path and skips `indentexpr` for the new line. The feedkeys path does run it.
The `InsertEnter`/`startinsert!` lifecycle was rejected: it duplicates native
Insert semantics, breaks counts and edge cases, and is expensive to test.

## Consequences

- The fix is 47 lines and keeps native Insert-mode behavior.
- The regression test must isolate fold state (`foldenable=false`) before
  asserting line positions, and separately verify that a real closed fold still
  opens after the fold.
- CI parity requires the pinned Neovim and `lazy-lock.json`; newer local plugin
  checkouts can compute different Treesitter indentation.
- The archived branch remains available for reference, but its unique work was
  deliberately not ported.
