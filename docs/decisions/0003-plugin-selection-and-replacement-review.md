# 0003 — Evidence-based plugin selection and replacement review

- **Status:** Accepted
- **Date:** 2026-11-16
- **Scope:** Neovim plugin changes and the installed plugin portfolio

## Decision

Before adding, removing, replacing, upgrading, or materially reconfiguring a
plugin, compare the current choice against maintained alternatives and built-in
Neovim/LSP capabilities. Include removing the dependency as a valid option. Do
not assume the current plugin is best merely because it already works or is
already in the lockfile.

The review must identify the real user-facing role, then evaluate upstream
maintenance and service availability, Neovim/API compatibility, unresolved
regressions, feature quality, latency/startup/runtime cost, dependencies and
build burden, security/privacy/data routing, license, pricing/API usage, vendor
lock-in, portability, and migration/rollback effort. Cite dated upstream evidence
and record uncertainties. Conclude with keep, replace, remove, or defer. No
unrelated bulk updates.

Any chosen implementation still needs behavior-first unit/integration/end-to-end
tests appropriate to the user-visible path. For external AI providers, a healthy
startup or a registered keymap is not enough: authentication and actual returned
suggestions must be verified.

## Retrospective application

Earlier plugin work was not consistently preceded by this documented comparison.
That does not prove those choices were wrong, but it also does not establish that
they remain the best choices today. Issue [#107](https://github.com/brianfiszman/dotfiles/issues/107)
tracks a retrospective inventory of every active plugin spec. It is an audit
only; recommended migrations must become separately scoped and tested work.

## Immediate case: AI inline completion

The current `ai/codeium.lua` spec uses `Exafunction/codeium.vim`. Its canonical
Vim/Neovim repository, `Exafunction/windsurf.vim`, and the companion
`Exafunction/windsurf.nvim` repository were archived on 2026-10-13. The
community replacement `monkoose/neocodeium` was archived on 2026-11-08; its
README says Codeium/Windsurf/Devin server access was discontinued in November
2026. Its maintainer also confirmed that completions no longer worked in
[issue #74](https://github.com/monkoose/neocodeium/issues/74). Therefore the old
[#69 InsertEnter-only change](https://github.com/brianfiszman/dotfiles/issues/69)
must not be implemented as written. Lazy-loading does not restore a retired
backend. No runtime removal or replacement has been made pending a trial.

### Candidates worth testing

- **[Minuet](https://github.com/milanglacier/minuet-ai.nvim):** currently
  maintained, supports cloud providers and local Ollama/llama.cpp, and provides
  its own virtual-text ghost-completion frontend with incremental acceptance.
  It avoids a proprietary background binary and uses Neovim's built-in
  `vim.system` plus curl. It needs an API key for hosted providers or local
  inference infrastructure; model quality, latency, and ongoing inference cost
  depend on the selected backend. Its license is GPL-3.0.
- **[GitHub Copilot](https://github.com/zbirenbaum/copilot.lua):** maintained
  turnkey hosted alternative. The plugin requires Neovim 0.11+ and defaults to
  GitHub's native Copilot Language Server; first use downloads a platform
  binary of roughly 75–110 MB. Copilot Free currently caps inline suggestions
  at 2,000 completions/month; Pro is listed at USD 10/month, with a separate
  monthly AI-credit allowance for premium model features. It is the simplest
  cloud-service trial, but brings vendor/account dependence.
- **[Tabby](https://github.com/TabbyML/vim-tabby):** self-hosted option with
  ghost-text completions. It requires a Tabby server plus a separate
  `tabby-agent` Node.js component (Node 18+), so it offers greater control at a
  higher setup and operations cost. The server and editor extension must be
  assessed separately for maintenance health.
- **[Supermaven](https://supermaven.com/blog/sunsetting-supermaven):** not a
  default new-adoption recommendation. Its official sunset announcement was
  2025-11-21; free autocomplete inference was promised for existing Neovim and
  JetBrains customers, not as a new, actively developed service.

### Current recommendation

Trial Minuet and Copilot first because both are direct candidates for the existing
inline ghost-text role but represent different trade-offs: provider choice and
local inference versus a turnkey hosted service. Include Tabby if self-hosting or
code privacy becomes a deciding requirement. Measure suggestion relevance,
time-to-first-suggestion, throughput/latency, acceptance ergonomics, false
positives, interruption rate, startup impact, authentication reliability, and
cost. Do not choose on feature lists or popularity alone.

## Sources checked on 2026-11-16

- [Exafunction/windsurf.vim archive](https://github.com/Exafunction/windsurf.vim)
- [Exafunction/windsurf.nvim archive](https://github.com/Exafunction/windsurf.nvim)
- [NeoCodeium archived repository and service notice](https://github.com/monkoose/neocodeium)
- [NeoCodeium service failure report and maintainer confirmation](https://github.com/monkoose/neocodeium/issues/74)
- [Minuet README and provider/frontend documentation](https://github.com/milanglacier/minuet-ai.nvim)
- [Minuet release history](https://github.com/milanglacier/minuet-ai.nvim/releases)
- [Copilot Lua README](https://github.com/zbirenbaum/copilot.lua)
- [Copilot plans and inline suggestion limits](https://docs.github.com/en/copilot/get-started/plans)
- [Tabby Vim/Neovim integration requirements](https://tabby.tabbyml.com/docs/extensions/installation/vim/)
- [Supermaven sunset announcement](https://supermaven.com/blog/sunsetting-supermaven)

No plugin spec, lockfile, runtime behavior, or installed dependency was changed
as part of this decision.
