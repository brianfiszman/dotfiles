---
name: neovim-dependency-management
description: Triage Neovim health reports, distinguish required tools from optional providers, provision dependencies through Mason or isolated environments, and diagnose local-versus-CI drift.
---

# Neovim dependency management

## Purpose

Treat `:checkhealth` as diagnostic evidence, not as a shopping list. A warning
does not automatically mean the editor is broken or that a system package should
be installed. Identify which feature needs the executable, who owns its
installation, and whether the current configuration actually uses it.

Use this skill with `neovim-maintenance` for dependency audits, optional tool
installation, Python/Ruby/Node providers, Mason packages, and local-versus-CI
environment mismatches.

## Triage workflow

1. Capture the complete `:checkhealth` output and exact Neovim version.
2. Record `stdpath("config")`, `stdpath("data")`, and the effective PATH from
   inside Neovim. Do not assume a terminal's PATH is identical to Neovim's.
3. Classify each finding:
   - **Runtime error:** a requested provider or feature could not start. Find
     the exact executable/module and the feature that requested it.
   - **Required external tool:** a configured feature cannot work without it.
   - **Optional provider/tool:** only required when a specific integration is
     used; document an opt-in setup path.
   - **Plugin recommendation:** an optional capability or icon/package
     recommendation, not a missing system dependency.
   - **Configuration warning:** filetype registration, keymap overlap,
     deprecation, or duplicate ownership. Fix configuration rather than
     installing executables.
   - **Package-manager state warning:** inspect existing directories and
     provenance before modifying or deleting anything.
4. Search the repository for the consumer and its package spec before choosing
   an installation method. Check whether the package is already available via
   Mason, lazy.nvim, a dedicated language environment, or the OS.
5. Propose the least invasive installation method and a verification command.
   Keep optional tools optional; do not install unrelated language runtimes just
   to make every health section green.

## Prefer Mason for supported command-line tools

Mason installs registered LSP servers, DAP adapters, linters, formatters, and
other developer tools under Neovim's data directory. It adds installed
executables to Neovim's PATH.

- Discover a package in `:Mason`.
- Install explicitly with `:MasonInstall <package>`.
- Inspect failures with `:MasonLog`.
- Verify the executable from the running Neovim process with
  `vim.fn.executable("<binary>") == 1`, then run its version command.
- Verify the relevant plugin healthcheck again.

For the current legacy `nvim-treesitter` setup, the Mason registry package is
`tree-sitter-cli`, which provides the `tree-sitter` executable and includes a
macOS ARM64 asset. The in-editor command is:

```vim
:MasonInstall tree-sitter-cli
```

This CLI is optional for the current locked plugin: its healthcheck says it is
needed for `:TSInstallFromGrammar`, not ordinary `:TSInstall`. Existing
parser binaries, highlighting, folds, and indent queries do not depend on the
CLI being on PATH. A missing CLI is therefore not, by itself, an explanation
for a parser or indentation runtime failure.

Do not add every Mason-detected language runtime to `ensure_installed`. A
Composer/PHP/Julia warning matters only when the maintainer uses the
corresponding package or workflow. Likewise, do not install Mercurial only to
silence Diffview when Git already satisfies its VCS requirement.

## Neovim external providers are not Mason packages

Provider health is separate from Mason's tool registry.

### Python

The Python provider requires Python 3.9+ and the `pynvim` Python package.
Keep it optional: ordinary Lua editing and Neovim startup must not depend on
a Python provider being installed.

Use `:DotfilesInstallPythonProvider` inside Neovim to opt in. The command uses
`python3` from Neovim's `PATH`, stages a dedicated virtualenv under
`${stdpath("data")}/python3-venv`, upgrades `pip`, installs `pynvim`, and verifies
both `pynvim` and `neovim` imports before activating it. It replaces the previous
environment only after validation succeeds, so missing Python, venv failures,
package-install failures, and import failures do not destroy a working provider.
It does not install Python globally or invoke an OS package manager.

Restart Neovim after provisioning. Early `init.lua` setup selects the dedicated
interpreter only when `vim.g.python3_host_prog` has not been configured manually.
Verify the real provider with `:checkhealth vim.provider` after restart.
The README documents an equivalent shell-based fallback.

The provider is optional for ordinary Lua editing. Do not make its installation
a first-start requirement.

### Other providers

- Node, Ruby, and Perl providers are independent from Mason. Install them only
  when a configured plugin or workflow uses them.
- For an unused optional provider, consider disabling it explicitly rather than
  installing an unused language runtime solely to remove a warning.
- A provider error is different from a compiler/parser error: identify the
  requested provider and host executable before changing build tools.

## Distinguish missing tools from configuration warnings

Examples:

- Missing `tree-sitter` is a CLI capability warning in the current legacy
  plugin, not proof that parser binaries are absent.
- Missing `hg` is not actionable when Git is installed and accepted by the
  plugin.
- Missing Composer, PHP, or Julia is relevant only to packages that need those
  ecosystems.
- Neorg key conflicts and WhichKey mapping-overlap warnings are configuration
  ownership issues, not executable dependencies.
- Unknown LSP filetypes require filetype registration or a configuration
  decision; installing a binary does not register them.
- Deprecation warnings identify an API migration in the owning plugin/config.
- A `vim.pack` lockfile warning while this repository uses lazy.nvim is not a
  request to install a tool. Inventory the package directory and identify its
  owner before generating a lockfile or removing anything. Never delete an
  existing plugin directory as an automatic health repair.

## Local-versus-CI parity

A green CI run proves only the exact source SHA and isolated environment that
ran. It does not install a patch or dependency on the maintainer's Mac.

Before changing dependencies or updating plugins, capture:

- `nvim --version` and the actual `:echo stdpath("config")` / data path;
- the config branch/commit and committed `lazy-lock.json` entry;
- the installed plugin checkout's actual `git rev-parse HEAD`;
- any local diff in the plugin checkout and whether the intended patch is
  present;
- Mason package path and `vim.fn.executable()` result;
- parser ABI and the actual installed parser files/features.

The lockfile records the intended plugin revision; it does not prove that the
local checkout has been restored to it. If a compatibility patch is carried in
the dotfiles branch, first verify that branch is installed in the active config
and that the matching downstream patch is present in the real plugin checkout.
Do not infer local state from a successful clean-install CI run.

Do not run `:Lazy update`, `:TSUpdate`, or manually edit a plugin checkout
until the current local revisions and diffs have been captured. Those operations
can destroy the evidence needed to explain a local-only failure.

## lazy.nvim build hooks versus startup hooks

In the repository's locked lazy.nvim revision
[`6c3bda4`](https://github.com/folke/lazy.nvim/blob/6c3bda4aca61a13a9c63f1c1d1b16b9d3be90d7a/doc/lazy.nvim.txt):

- A plugin `build` function runs when a plugin is installed or updated. A
  change to the plugin spec alone does not guarantee that an already-installed
  checkout will rerun its build function.
- `:Lazy build nvim-treesitter` explicitly forces the build function for an
  existing checkout.
- A plugin `init` callback runs on every startup before lazy.nvim loads start
  plugins. It is the appropriate hook for a small compatibility patch that
  must be present before plugin modules load.

For a compatibility patch that must work for both fresh and existing checkouts,
use both hooks: `init` handles an existing directory at startup; `build`
handles a fresh clone after installation. The `init` helper must safely skip a
directory that does not exist yet, and both paths must be idempotent and guard
the exact locked plugin revision.

The regression test should prove both lifecycles, not just clean installation:
restore a fresh plugin and let its build hook apply the patch, reverse the patch
on that isolated checkout to simulate an already-installed old copy, then start
Neovim normally and assert that the `init` hook reapplies it before plugin load.
The compatibility patch was merged to `master` as [commit `f5b2a1f`](https://github.com/brianfiszman/dotfiles/commit/f5b2a1ff7d8f0277ad33e50b64e9e9f99b34186f) through PR [#95](https://github.com/brianfiszman/dotfiles/pull/95). Its exact PR head `e61e0cafd41443cf4082f7c12ca60177cf90597d` passed workflow [#43749144164](https://github.com/brianfiszman/dotfiles/actions/runs/43749144164). This CI evidence validates fresh installs and simulated pre-existing checkouts only; it does not establish the state of the maintainer's Mac.

## Installation safety

- Never add `sudo`, Homebrew, apt, pacman, or another OS package-manager call
  to the dotfiles installer.
- Keep system prerequisites separate from Neovim-managed tools.
- Use Mason for registry-supported developer tools; use a dedicated environment
  for language modules/providers.
- Make installs explicit, repeatable, idempotent, and verifiable.
- Preserve existing state on failure. Do not overwrite a working environment or
  remove an unknown package directory without a backup and a clear owner.
- Test installer/provider changes with temporary HOME and XDG paths. Never use
  the maintainer's real home in automated tests.

## Definition of done

A dependency task is complete when the feature that needs the tool works, the
tool is discoverable from Neovim's actual PATH, the relevant healthcheck is
understood, failure paths are actionable, and the setup is documented. A
health report with fewer warnings is not sufficient if the feature remains
untested or an unrelated package was installed.
