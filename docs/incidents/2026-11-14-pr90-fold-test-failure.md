# Incident — PR #90 fold fixture failure (2026-11-14)

- **Issue:** [#89](https://github.com/brianfiszman/dotfiles/issues/89)
- **Affected PR:** [#90](https://github.com/brianfiszman/dotfiles/pull/90), archived at
  `archive/indented-substitute-43` (`85f1ec7`)
- **Replacement:** [#93](https://github.com/brianfiszman/dotfiles/pull/93)

## Symptom

The TypeScript `o` scenario failed: the test expected the new line at row 3, but
the editor opened it at row 4. The production mapping looked correct.

## Root cause

The test fixture inherited `foldmethod=syntax` from the real Neovim
configuration and had folds enabled. The source line at row 2 was inside a
closed fold spanning rows 1–3. Native `o` therefore opened the new line after
the fold boundary at row 4.

Evidence:

- `foldclosed(2)` returned `1` inside the fixture.
- With `foldenable=false`, native `o` opened row 3.
- With folds enabled, the same native behavior opened row 4, which is correct
  for a closed fold.

The failure was a test-fixture isolation bug, not a regression in the mapping.

## Why it took so long

- The fixture did not assert its own preconditions, so fold state was invisible.
- The branch kept adding lifecycle machinery (`InsertEnter`, `startinsert!`) and
  probe files instead of reducing the failing scenario to one variable.
- The investigation treated a test failure as evidence about the production
  mapping without first proving what native `o` does under the same options.

## Corrective actions

- The replacement test sets `foldenable=false` and asserts `foldclosed() == -1`
  before line-position assertions.
- A separate scenario verifies that a real closed fold still opens after the
  fold, preserving native behavior.
- The mapping skips reindentation when the source line is in a closed fold.
- The replacement uses the pinned Neovim 0.11.3 and committed `lazy-lock.json`
  for CI parity.

## Lesson

Before asserting a line operation, reset every option that can move the line:
folds, `autoindent`, `smartindent`, `expandtab`, and filetype indent settings.
Assert the reset. A failing editor test is not evidence about the mapping until
the fixture's starting state is proven.
