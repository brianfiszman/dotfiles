# Neovim Configuration Modernization

Tracking issue: [#16 — Neovim configuration modernization](https://github.com/brianfiszman/dotfiles/issues/16)

This backlog describes the changes in terms of what you should notice while using Neovim. Parent issues group related work; the smaller issues are independently testable tasks.

## 1. Reliable installation and startup

- [#46 — Remove obsolete dein.vim setup instructions](https://github.com/brianfiszman/dotfiles/issues/46)
- [#47 — Back up existing Neovim and Emacs configs before replacing them](https://github.com/brianfiszman/dotfiles/issues/47)
- [#48 — Keep sudo and OS package installation out of the dotfiles installer](https://github.com/brianfiszman/dotfiles/issues/48)
- [#49 — Make Neovim-only, Emacs-only, and combined setup explicit](https://github.com/brianfiszman/dotfiles/issues/49)
- [#51 — Show a useful error when lazy.nvim cannot be installed](https://github.com/brianfiszman/dotfiles/issues/51)
- [#66 — Do not copy the machine-specific Python virtualenv](https://github.com/brianfiszman/dotfiles/issues/66)
- [#68 — Register every plugin so clean installs can sync them](https://github.com/brianfiszman/dotfiles/issues/68)
- [#50 — Run a clean headless startup test in GitHub Actions](https://github.com/brianfiszman/dotfiles/issues/50)

## 2. LSP and language tooling

Parent: [#17 — LSP migration](https://github.com/brianfiszman/dotfiles/issues/17)

- [#61 — Give each language server one setup owner](https://github.com/brianfiszman/dotfiles/issues/61)
- [#62 — Replace neodev with lazydev for Lua development](https://github.com/brianfiszman/dotfiles/issues/62)
- [#57 — Choose one intentional linter per language](https://github.com/brianfiszman/dotfiles/issues/57)
- [#58 — Avoid running linters repeatedly while opening and editing files](https://github.com/brianfiszman/dotfiles/issues/58)
- [#64 — Pin the Treesitter API and make parser updates predictable](https://github.com/brianfiszman/dotfiles/issues/64)

## 3. Editing behavior and keymaps

Parent: [#22 — Editing UX and autocmds](https://github.com/brianfiszman/dotfiles/issues/22)

- [#52 — Keep an active snippet alive while the cursor is idle](https://github.com/brianfiszman/dotfiles/issues/52)
- [#53 — Do not run file-change checks on every window switch](https://github.com/brianfiszman/dotfiles/issues/53)
- [#55 — Use one scroll-animation system](https://github.com/brianfiszman/dotfiles/issues/55)
- [#56 — Choose one default for line wrapping](https://github.com/brianfiszman/dotfiles/issues/56)
- [#59 — Make Tab and Shift-Tab completion behavior deterministic](https://github.com/brianfiszman/dotfiles/issues/59)
- [#60 — Make the DAP Run with Args mapping work](https://github.com/brianfiszman/dotfiles/issues/60)

## 4. Startup and performance

Parent: [#18 — Lazy loading and startup performance](https://github.com/brianfiszman/dotfiles/issues/18)

- [#54 — Stop rebuilding all help tags on every startup](https://github.com/brianfiszman/dotfiles/issues/54) (removed from the initial implementation branch)
- [#63 — Load test, debug, and search tools when they are first used](https://github.com/brianfiszman/dotfiles/issues/63)
- [#65 — Avoid machine-specific shell, font, and clipboard assumptions](https://github.com/brianfiszman/dotfiles/issues/65)

## 5. Parent workstreams

The original workstream issues remain useful as summaries of broader areas:

- [#19 — Linting cleanup](https://github.com/brianfiszman/dotfiles/issues/19)
- [#20 — Treesitter audit](https://github.com/brianfiszman/dotfiles/issues/20)
- [#21 — Completion and snippets](https://github.com/brianfiszman/dotfiles/issues/21)
- [#23 — Remove the tracked virtualenv from Git](https://github.com/brianfiszman/dotfiles/issues/23)
- [#24 — Startup cleanup](https://github.com/brianfiszman/dotfiles/issues/24)
- [#25 — DAP cleanup](https://github.com/brianfiszman/dotfiles/issues/25)

## Definition of done

- Existing daily editing workflows and keymaps continue to work.
- Each plugin, server, and linter has one clear initialization path.
- Startup and representative editing workflows are measured before and after.
- No machine-specific generated environments or secrets are committed.
- Changes land in small, reviewable commits or PRs.
- The headless smoke test passes, and interactive behavior is manually checked where headless testing cannot prove it.

## Working agreement

See [AGENTS.md](../AGENTS.md) and the [Neovim maintenance skill](../.agents/skills/neovim-maintenance/SKILL.md) for how issues are written, changes are scoped, and test results are reported.
