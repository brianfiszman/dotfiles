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

For discovery and research methodology, follow
[the dependency-research skill](../../.agents/skills/dependency-research/SKILL.md).
It requires unseeded discovery, live GitHub stars, the last commit on the actual
default branch, role-level feature verification, and a separate accounting of
plugin licensing, model/backend pricing, local infrastructure, quotas, and data
terms.

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

## Immediate case: AI tools for Neovim

### Blind discovery method

This investigation deliberately did not use the name of the candidate Brian had
previously favored. Initial searches were:

- "Neovim AI coding assistant plugins inline completion agentic chat code editing"
- "best Neovim AI plugins autocomplete ghost text chat coding agent comparison current"
- "Neovim AI coding assistant plugins GitHub repository popularity alternatives code completion agent"

Discovery sources included the GitHub catalogues
[awesome-neovim-sorted](https://github.com/jupblb/awesome-neovim-sorted) and
[neovim-ai-plugins](https://github.com/ColinKennedy/neovim-ai-plugins). They
surfaced the project later identified as Avante as the top-popularity candidate,
without seeding the search with its name. Its current GitHub API star count and
latest default-branch commit were then verified directly.

The metrics below were checked on **2026-11-16**. Stars are live repository API
counts. "Latest commit" is the newest commit returned by the actual default
branch's commits endpoint, not repository `updated_at` or `pushed_at`.

| Project | Stars | Default branch / latest commit | Latest release | Main utility | Cheapest workable path |
|---|---:|---|---|---|---|
| [Avante](https://github.com/avante-corp/avante.nvim) | 18,196 | [`main` · Nov 16, 2026](https://github.com/avante-corp/avante.nvim/commit/045fc710fe2dfbe77c4b5aae58974f09953dd997) (README TOC command) | [v0.5.0 · Oct 31](https://github.com/avante-corp/avante.nvim/releases/tag/v0.5.0) | All-in-one chat, agentic edits/diffs, ACP/MCP; experimental automatic ghost suggestions | Plugin Apache-2.0/free; Ollama or llama.cpp local inference is $0 per request but needs hardware. Hosted APIs are usually billed; Gemini has a limited free API tier |
| [Copilot.vim](https://github.com/github/copilot.vim) | 11,712 | [`release` · Jan 9, 2026](https://github.com/github/copilot.vim/commit/a12fd5672110c8aa7e3c8419e28c96943ca179be) | No latest GitHub release returned | Official automatic inline completion | Copilot Free: 2,000 completions/month; paid plans for higher usage |
| [CodeCompanion](https://github.com/olimorris/codecompanion.nvim) | 6,945 | [`main` · Nov 13, 2026](https://github.com/olimorris/codecompanion.nvim/commit/8ffcc9a78d87732a26243de37ef697f54efe91c2) (v20.2.0 release) | [v20.2.0 · Nov 13](https://github.com/olimorris/codecompanion.nvim/releases/tag/v20.2.0) | Chat, inline code transformations, code review, ACP/MCP agents; not automatic ghost-text completion | Plugin Apache-2.0/free; local Ollama needs no API key; hosted model APIs/subscriptions cost money |
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) | 4,094 | [`master` · Nov 12, 2026](https://github.com/zbirenbaum/copilot.lua/commit/3547efbff9adeecbd9d431c0a2a8707b7f6a4131) (updates Copilot LSP) | [v3.2.4 · Nov 12](https://github.com/zbirenbaum/copilot.lua/releases/tag/v3.2.4) | Automatic inline completions; optional Next Edit Suggestions integration | Copilot Free: 2,000 completions/month; Pro listed at $10/month |
| [OpenCode.nvim](https://github.com/nickjvandyke/opencode.nvim) | 3,918 | [`main` · Oct 30, 2026](https://github.com/nickjvandyke/opencode.nvim/commit/4851ae503585dc5142ad66a98e8952a74e1f7b3a) (release CI gate) | [v1.0.2 · Sep 14](https://github.com/nickjvandyke/opencode.nvim/releases/tag/v1.0.2) | Neovim frontend for OpenCode CLI, prompts, context and diff review; not typing autocomplete | Plugin MIT/free; local Ollama/LM Studio/vLLM is free per request; ChatGPT Plus/Pro can use included plan usage; other API providers billed |
| [CopilotChat.nvim](https://github.com/CopilotC-Nvim/CopilotChat.nvim) | 3,648 | [`main` · Oct 23, 2026](https://github.com/CopilotC-Nvim/CopilotChat.nvim/commit/2b7da97d655416462d4d5c38d0eb1f1eacc900a2) (documentation generation) | [v4.7.4 · Oct 1, 2025](https://github.com/CopilotC-Nvim/CopilotChat.nvim/releases/tag/v4.7.4) | Chat with Copilot, diffs and custom providers; not automatic autocomplete | Plugin GPL-3.0/free; Copilot Free is limited, or configure a local provider such as Ollama |
| [ClaudeCode.nvim](https://github.com/coder/claudecode.nvim) | 3,158 | [`main` · Nov 16, 2026](https://github.com/coder/claudecode.nvim/commit/6ad8e0fdbda84486f13f7f1fa4802942f4877f13) (skills hook fix) | [v0.4.0 · Nov 9](https://github.com/coder/claudecode.nvim/releases/tag/v0.4.0) | Neovim integration for the Claude Code CLI, terminal and proposed-edit diffs | Plugin MIT/free; Claude Code requires a Pro/Max subscription or billable Anthropic Console/enterprise access |
| [Sidekick.nvim](https://github.com/folke/sidekick.nvim) | 2,820 | [`main` · Sep 8, 2026](https://github.com/folke/sidekick.nvim/commit/3d80a47e6375f6d647c9695d3afea6fa1b3275df) (terminal fix) | [v2.3.0 · Mar 20](https://github.com/folke/sidekick.nvim/releases/tag/v2.3.0) | Copilot Next Edit Suggestions plus a terminal for external AI CLIs | Plugin Apache-2.0/free; NES relies on Copilot LSP access and CLI usage follows each agent's pricing |
| [llama.vim](https://github.com/ggml-org/llama.vim) | 2,205 | [`master` · Sep 29, 2026](https://github.com/ggml-org/llama.vim/commit/e1ca1cc6af9da73f4ae21f810f33909d515592e6) (configurable FIM debounce) | [v0.1.0 · Aug 24](https://github.com/ggml-org/llama.vim/releases/tag/v0.1.0) | Local LLM Fill-in-the-Middle completions | Plugin MIT/free; local llama.cpp inference avoids API charges but needs compute and model storage |
| [Minuet](https://github.com/milanglacier/minuet-ai.nvim) | 1,463 | [`main` · Oct 7, 2026](https://github.com/milanglacier/minuet-ai.nvim/commit/50bf63b031c0391e926fdf0b3d044d37846e6e34) (README documentation) | [v0.10.0 · Jul 31](https://github.com/milanglacier/minuet-ai.nvim/releases/tag/v0.10.0) | Dedicated automatic inline completion with cloud and local providers | Plugin GPL-3.0/free; local Ollama/llama.cpp or a limited Gemini API free tier; other APIs billed |
| [Agentic.nvim](https://github.com/carlos-algms/agentic.nvim) | 660 | [`main` · Nov 8, 2026](https://github.com/carlos-algms/agentic.nvim/commit/4750d6ce4298b3018dd67f975a1457afbeeaa09f) (before-first-prompt hooks) | No latest GitHub release returned | ACP chat frontend that reuses installed agent CLIs and their auth/config | Plugin MIT/free; actual model cost/limits come from the connected CLI or provider |
| [Tabby vim-tabby](https://github.com/TabbyML/vim-tabby) | 119 | [`main` · Jan 13, 2025](https://github.com/TabbyML/vim-tabby/commit/5e30c429354b8e0fd5bbc7634be4abac5518bb80) (v2.0.2 release) | No latest GitHub release returned | Self-hosted ghost-text completion via Tabby server | Open-source/self-hosted; server compute is the cost. Plugin also needs a separate Node 18+ `tabby-agent`; upstream editor plugin is stale |

This table is deliberately not a single score. Several high-star candidates solve
different jobs; their popularity should not make them look interchangeable.

### Findings by workflow

**Best all-in-one candidate by the requested criteria: Avante.** It led the
blind discovery set by a large margin, had 18,196 stars, and its main branch had
a commit on the research date. Its utility is broad: chat, code edits/diffs,
agentic mode, ACP/MCP providers, project instructions, and optional automatic
suggestions. The plugin is Apache-2.0. It can use Ollama/llama.cpp locally, so a
no-subscription setup is possible; the default provider is Claude, however, and
hosted inference is not free merely because the plugin is.

Important cautions from the actual current source:

- `behaviour.auto_suggestions` is **experimental and false by default**.
- The default suggestion debounce and throttle are both 600 ms.
- The current implementation submits the buffer contents and diagnostics to the
  selected LLM and displays structured virtual-text suggestions. This is not
  necessarily as cheap, fast, or context-efficient as a dedicated completion API.
- The default config currently has `auto_approve_tool_permissions = true` and
  `prompt_logger.enabled = true` (logs are written under Neovim's cache path).
  Disable automatic tool approval and prompt logging explicitly before using
  agentic mode with real projects unless the user deliberately opts in.
- Prebuilt Rust libraries are downloaded with `:AvanteBuild`; building from
  source requires Cargo/Rust. Dependencies include Plenary, Nui, and
  mega.cmdparse/mega.logging.
- The project warns that the Copilot provider is risky for high-frequency
  automatic suggestions; do not assume a Copilot subscription is a safe Avante
  autocomplete backend.

**Strongest all-in-one alternative: CodeCompanion.** It has 6,945 stars and a
recent main-branch commit. It covers multi-provider chat, user-invoked inline
transformations, code review, ACP, and MCP. It can use Ollama locally with no API
key. Its inline interaction edits a buffer after a user prompt; it is not
automatic ghost text while typing. This distinction matters when comparing it
with the former Codeium role.

**Dedicated inline completion choices:** copilot.lua, Minuet, llama.vim, and
Avante's experimental suggestion engine. copilot.lua is actively maintained and
the most straightforward turnkey hosted option, with Copilot Free's 2,000
monthly completions or the paid Pro plan. Minuet has a more recent code commit
than its star count might suggest and supports local or hosted models. llama.vim
is a local FIM choice. Avante can provide inline suggestions, but they are
currently experimental and more general-purpose than a dedicated completion
engine.

**Agent frontends:** OpenCode.nvim, ClaudeCode.nvim, and Agentic.nvim mainly
connect Neovim to separate coding-agent CLIs. The plugin may be free while the
agent requires an existing subscription, API billing, or local hardware.
OpenCode documents local Ollama/LM Studio/vLLM providers and ChatGPT Plus/Pro
authentication that consumes the plan's included usage.

**Self-hosted option:** Tabby is conceptually attractive for local/private
completion, but the Neovim editor plugin's latest default-branch commit is
January 13, 2025. The current official setup also requires a Tabby server and a
separate `tabby-agent` installed through npm (Node.js 18+). Do not recommend
fresh adoption without further verification of the editor integration's
maintenance.

### Recommendation for Brian's criteria

Avante was selected as the first general AI coding assistant and has now
been integrated into the active Neovim configuration through
[PR #110](https://github.com/brianfiszman/dotfiles/pull/110), merged on
2026-11-16. This follows the blind discovery result rather than a search seeded
with Avante's name. The integration uses local Ollama by default and deliberately
enables Avante's experimental automatic suggestions as the Codeium replacement.

That is a **selection and implementation decision, not proof that the complete
local workflow is healthy**. The exact PR #110 head passed the clean Linux
plugin restore, native build, and Neovim startup workflow, but the maintainer
reported that installing Avante on their local macOS setup is currently failing.
The local error was captured on 2026-11-17: Avante's source build was
terminated with signal 15 after reaching the build timeout, without a Rust
compiler or linker diagnostic. PR [#111](https://github.com/brianfiszman/dotfiles/pull/111)
proposes using Avante's release-matched prebuilt libraries instead. Authentication
to local Ollama, actual suggestions while typing, acceptance/dismissal, latency,
and quality remain unverified. Keep the integration issue open until those
checks are completed. CodeCompanion remains the strongest all-in-one alternative;
copilot.lua and Minuet remain dedicated-completion alternatives if Avante's
experimental suggestions prove unsuitable.

### Pricing and free-use sources

- [GitHub Copilot plans and Free/Pro limits](https://docs.github.com/en/copilot/get-started/plans)
- [GitHub Copilot Free setup and 2,000 completion limit](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/enable-copilot/set-up-for-self)
- [OpenCode provider authentication and subscription usage](https://opencode.ai/docs/providers)
- [OpenCode local model configuration](https://opencode.ai/docs/models)
- [Gemini API free tier and data policy](https://ai.google.dev/gemini-api/docs/pricing)
- [Ollama local use and pricing](https://ollama.com/pricing)
- [Claude Code authentication and subscription/API requirements](https://code.claude.com/docs/en/getting-started)
- [Tabby self-hosted principles](https://tabby.tabbyml.com/docs/)
- [Tabby Vim/Neovim server and agent requirements](https://tabby.tabbyml.com/docs/extensions/installation/vim/)



The Gemini free API tier has limited model/rate access and Google states that content submitted on the free tier may be used to improve its products. Do not describe it as a private-code path; check the current data terms before sending proprietary code. The local Ollama path avoids sending prompts to a hosted provider, but still has hardware/model-license costs.

### Technical sources

- [Avante README](https://github.com/avante-corp/avante.nvim)
- [Avante config defaults](https://github.com/avante-corp/avante.nvim/blob/main/lua/avante/config.lua)
- [Avante suggestion implementation](https://github.com/avante-corp/avante.nvim/blob/main/lua/avante/suggestion.lua)
- [Avante latest default-branch commit](https://github.com/avante-corp/avante.nvim/commit/045fc710fe2dfbe77c4b5aae58974f09953dd997)
- [CodeCompanion inline interaction documentation](https://github.com/olimorris/codecompanion.nvim/blob/main/doc/configuration/inline.md)
- [CodeCompanion local-model documentation](https://github.com/olimorris/codecompanion.nvim/blob/main/doc/codecompanion.txt)
- [Copilot.lua README](https://github.com/zbirenbaum/copilot.lua)
- [Minuet README](https://github.com/milanglacier/minuet-ai.nvim)
- [llama.vim README](https://github.com/ggml-org/llama.vim)
- [OpenCode.nvim README](https://github.com/nickjvandyke/opencode.nvim)
- [ClaudeCode.nvim README](https://github.com/coder/claudecode.nvim)
- [Agentic.nvim README](https://github.com/carlos-algms/agentic.nvim)
- [Sidekick.nvim README](https://github.com/folke/sidekick.nvim)
- [CopilotChat.nvim README](https://github.com/CopilotC-Nvim/CopilotChat.nvim)
- [Tabby vim-tabby README](https://github.com/TabbyML/vim-tabby)

## Earlier Codeium/Windsurf decision and implementation outcome

The retired `Exafunction/codeium.vim` integration was not a viable path to
preserve. Its canonical Vim/Neovim repositories
(`Exafunction/windsurf.vim` and `Exafunction/windsurf.nvim`) were archived on
2026-10-13. The community replacement `monkoose/neocodeium` was archived on
2026-11-08; its README says Codeium/Windsurf/Devin server access was
discontinued in November 2026. Its maintainer confirmed that completions no
longer worked in [NeoCodeium issue #74](https://github.com/monkoose/neocodeium/issues/74).
Lazy-loading alone could not restore that retired backend.

The selected replacement was implemented in
[PR #110](https://github.com/brianfiszman/dotfiles/pull/110), merged into
`master` on 2026-11-16 as
[`5b0808f`](https://github.com/brianfiszman/dotfiles/commit/5b0808f2f86de558c7384fe36e5d43fc31746da8).
The active configuration is now `.config/nvim/lua/ai/avante.lua`:

- Avante loads on `InsertEnter`, keeping ordinary startup lazy.
- Chat and automatic suggestions use the local Ollama provider by default,
  with `qwen3:8b` and `127.0.0.1:11434` as defaults.
- Automatic suggestions are explicitly enabled, with an 800 ms debounce and
  1200 ms throttle.
- Tool approval remains interactive, generated diffs are not auto-applied,
  Git-ignored files are not exposed to tools, and prompt replay logging is off.

The exact PR #110 head
[`647c817`](https://github.com/brianfiszman/dotfiles/commit/647c817f9fea50a6dbc66cf9bb0f6c46b3d44cf0)
passed workflow [#43976964232](https://github.com/brianfiszman/dotfiles/actions/runs/43976964232):
fast checks, macOS provider-provisioning checks, and a fresh isolated Linux
Neovim 0.12.6 install that restored locked plugins, ran their build hooks
(including Avante's Rust/Cargo build), and started Neovim normally. This proves
that CI's Linux installation/build path works; it does not prove a local macOS
installation or a live Ollama completion.

On 2026-11-17 the maintainer supplied the local Lazy build log. It shows
`cargo build --workspace --release --no-default-features --features=luajit`
compiling the Avante Rust dependency graph until
`make: *** [luajit] Terminated: 15`; the log explicitly says the process was
killed because it reached the timeout. The visible Cargo dependency warnings
are non-fatal. This identifies the local failure as a source-build timeout,
not a compiler/linker error.

Avante 0.5.0's `:AvanteBuild` command defaults to `source=false` and downloads
the prebuilt release libraries. PR
[#111](https://github.com/brianfiszman/dotfiles/pull/111) proposes changing the
Lazy build hook to that command, asserting the native artifacts after restore,
and exercising the real locked-plugin restore on macOS CI. Until that PR's
macOS/Linux checks and a local install pass, issue
[#69](https://github.com/brianfiszman/dotfiles/issues/69) remains open for the
installation fix and the separate live Ollama/suggestion smoke tests.


### macOS installation path verification — 2026-11-17

The current lockfile pins Avante to
[`045fc71`](https://github.com/avante-corp/avante.nvim/commit/045fc710fe2dfbe77c4b5aae58974f09953dd997).
At that exact revision, `lua/avante/version.lua` returns `0.5.0`, and the active
plugin specification sets `build = "make"`.

The pinned upstream
[Makefile](https://github.com/avante-corp/avante.nvim/blob/045fc710fe2dfbe77c4b5aae58974f09953dd997/Makefile)
defines `all: luajit`; that target runs
`cargo build --workspace --release --no-default-features --features=luajit`
and copies the compiled Rust libraries into Avante's `lua/` directory. Thus
the current Lazy build hook is a **source build**, not a prebuilt-binary
download. It requires `make`, Rust/`cargo`, and a working native C/linker
toolchain on macOS. The local dotfiles README currently documents these
requirements, including Xcode Command Line Tools.

There is also a viable prebuilt route. The v0.5.0
[release notes](https://github.com/avante-corp/avante.nvim/releases/tag/v0.5.0)
state that `:AvanteBuild --version=v0.5.0` downloads the native libraries
rather than compiling them. The pinned upstream
[build.sh](https://github.com/avante-corp/avante.nvim/blob/045fc710fe2dfbe77c4b5aae58974f09953dd997/build.sh)
maps macOS `arm64` to `aarch64`, supports `x86_64`, and selects the
LuaJIT archive by default. The v0.5.0 release asset mirror lists both
`avante_lib-darwin-aarch64-luajit.tar.gz` and
`avante_lib-darwin-x86_64-luajit.tar.gz`
([asset index](https://sourceforge.net/projects/avante-nvim.mirror/files/v0.5.0/)).
This path can avoid a local Rust/C compilation, while still requiring network
access plus `curl` and `tar`.

There is an upstream documentation inconsistency worth preserving: the current
README's Lazy example discusses `make BUILD_FROM_SOURCE=true`, but the Makefile
at the exact locked commit has no `BUILD_FROM_SOURCE` switch and its default
target compiles from source. The pinned Makefile and observed Lazy hook therefore
determine the behavior of this configuration.

**CI coverage correction:** the successful job named
`Python provider provisioning (macOS)` runs
[`scripts/test-python-provider-macos.sh`](https://github.com/brianfiszman/dotfiles/blob/master/scripts/test-python-provider-macos.sh);
it does not install Avante or execute its build hook. The actual locked-plugin
restore and build-hook run is the separate Ubuntu
`Fresh install and headless startup` job, which does include Avante's
`make` hook. Consequently, the passing workflow does not demonstrate that
Avante's native libraries build on macOS.

This narrows the likely failure classes but does not identify the user's actual
failure. Missing Cargo/Rustup or Xcode Command Line Tools is one plausible cause;
a compiler/linker error or network/build-hook problem is also possible. Do not
change the build strategy or attribute the failure until the original local
command and error output are available. If the output points to the native
toolchain, evaluate switching the plugin hook to the version-matched prebuilt
release path and add a macOS Avante install test. Issue [#69](https://github.com/brianfiszman/dotfiles/issues/69)
remains open for that diagnosis and the separate live Ollama/suggestion tests.


## Scope boundary

This ADR records the research, selection rationale, and subsequent implementation
status. The initial Avante plugin specification, lockfile, and automated
configuration checks were changed in PR #110. The prebuilt-install change and
macOS plugin-restore coverage are proposed separately in PR #111, not in this
documentation PR. The local build timeout is diagnosed, but the proposed
prebuilt path still needs its CI and local verification; live Ollama behavior
also remains unverified. Any later change of provider or replacement plugin
must be separately scoped and tested against the actual user workflow.
