# Dotfiles

Personal shell, terminal, editor, and development-tool configuration.

## Neovim

The Neovim configuration lives in `.config/nvim` and uses **lazy.nvim**. The
first Neovim launch bootstraps lazy.nvim from Git; you do not need to install
dein.vim or run a manual plugin-manager command.

### Requirements

- Neovim 0.12.6 or newer.
- Git (used by lazy.nvim to download plugins).
- Internet access on the first launch.
- `make` and a C build toolchain for other native plugin build hooks.
  On macOS, install the Xcode Command Line Tools separately.
- `curl` and `tar` for Avante's release-matched prebuilt native libraries.
  Rust/`cargo` are only needed when explicitly building Avante from source with
  `:AvanteBuild source=true`.
- A terminal with a Nerd Font is recommended for icons, but the font is not
  required to start Neovim.

Mason provisions the configured language servers, formatters, and debug
adapters inside Neovim's data directory. Node.js 22.22.2 or newer plus npm must
be available on PATH for the current TypeScript language server and npm-backed
JavaScript tooling. Other optional system tools used by plugins remain
separately managed. The dotfiles installer does not use `sudo` or modify OS
packages.

The Go plugin does not bulk-install its optional helper binaries during setup.
Open a Go file and run `:GoInstallBinaries` when you want the full toolset.

Neorg's Norg and Norg Meta parsers are installed as plugin dependencies and exposed
to Neovim's runtimepath automatically; no separate parser installation is needed.

### Install Neovim configuration

From a clone of this repository:

```sh
bash ./install.sh --nvim
```

The installer:

1. Copies the Neovim configuration to `${XDG_CONFIG_HOME:-~/.config}/nvim`.
2. Excludes the repository's generated `venv` directory.
3. Moves an existing Neovim configuration to a timestamped backup before
   installing the new one.
4. Leaves Emacs, system packages, and unrelated files alone.

To preview the operation without changing anything:

```sh
bash ./install.sh --nvim --dry-run
```

The default command `bash ./install.sh` also installs **Neovim only**.
Use `--emacs` to install only Emacs files, or `--all` to install both editor
configurations.

### First launch

After installation, open Neovim:

```sh
nvim
```

On its first launch, `init.lua` downloads lazy.nvim and lazy.nvim installs the
plugins declared by the configuration. This requires Git and internet access.
On ordinary startup, Mason also ensures configured tools are present: the
TypeScript and ESLint language servers, Prettier, the JavaScript debug adapter,
and the pinned Tree-sitter CLI. Missing packages are installed automatically;
automatic package updates are disabled, so an ordinary restart does not update
already-installed tools. Use `:Mason` to inspect package status and `:Lazy` to
inspect plugin status.

If lazy.nvim cannot be downloaded, Neovim displays an actionable error. Check
that Git is installed and that the network can reach GitHub, then restart Neovim.

### JavaScript and TypeScript tooling

The normal-startup Mason setup provisions:

- `ts_ls` (`typescript-language-server`) for TypeScript and JavaScript language features.
- `eslint` (`eslint-lsp`) for ESLint diagnostics and save-time fixes.
- `prettier` as the default JS/TS formatter when a project-local or Mason-provided
  `prettierd` is not available.
- `js-debug-adapter` for Node.js and browser debugging.

Add `eslint` to each project's `devDependencies` and keep its configuration in
that project. The ESLint language server resolves the workspace's ESLint package
and rules; Mason installs the server, not a global replacement for the project's
linter. This avoids mismatches between the editor and the project's own scripts.

The JavaScript debug adapter is provisioned ahead of time, but the DAP plugins
and UI remain unloaded until a debugging command or mapping is invoked.

Neotest supports project-local Jest, Vitest, and Mocha installations. Keep the
runner in each project's `devDependencies`; its adapter discovers the runner
and configuration from that workspace. Use `<leader>tt` for the nearest test,
`<leader>tf` for the current file, and `<leader>td` to debug a test through
the JavaScript DAP adapter. Ordinary test runs do not load DAP.

### Editing

- In Normal mode, **Ctrl+F** runs the shared `:Format` command through Conform.
  For JavaScript and TypeScript it selects `prettierd` when available, otherwise
  `prettier`, and follows the project's Prettier configuration.
- LuaLS plugin type libraries are supplied by lazydev, which loads only for Lua buffers.
- ESLint diagnostics for JavaScript/TypeScript come from the ESLint language
  server. Its `LspEslintFixAll` action still runs before saving an attached buffer.
- Use `K` for symbol documentation, `<leader>DF` for the diagnostic under the
  cursor, and `[d` / `]d` to move between diagnostics.

### AI assistant (Avante)

Avante.nvim replaces the retired Codeium completion integration with local
automatic inline suggestions, plus on-demand codebase chat, user-invoked edits,
diff review, and agentic workflows. It stays unloaded during ordinary startup
and loads on the first InsertEnter or an Avante command/key trigger.

The default backend is **local Ollama** at `http://127.0.0.1:11434`, using
`gemma4:12b`. Install Ollama separately, then start its service and download the
model:

```sh
ollama serve
ollama pull gemma4:12b
```

Skip `ollama serve` when the Ollama app/service is already running. Open Neovim
and use:

- Automatic inline suggestions appear while typing in Insert mode.
- `<M-l>`: accept the current suggestion.
- `<M-]>` / `<M-[>`: move to the next/previous suggestion.
- `<C-]>`: dismiss the current suggestion.
- `<leader>at`: open or close the Avante assistant sidebar.
- `<leader>aa`: ask about the current code.
- `<leader>ae` (Visual mode): edit the selected code.

Override the local endpoint or model before launching Neovim:

```sh
export AVANTE_OLLAMA_ENDPOINT="http://127.0.0.1:11434"
export AVANTE_OLLAMA_MODEL="gemma4:12b"
```

The model is downloaded and run by Ollama; local inference has no per-request
API fee, but it uses local memory, compute, storage, and power. The default
endpoint is loopback. Changing it to a remote endpoint sends the selected
project context to that host.

Automatic suggestions also respect the project's `.gitignore`, so they are
not requested for Git-ignored files.

The assistant's conversation/session history is still stored locally under
Neovim's state directory (`stdpath("state")/avante`). Disabling prompt logging
turns off the separate timestamped prompt replay/debug log; it does not disable
the normal local conversation history.

Avante's automatic inline suggestions are enabled and use the same local
Ollama model as the assistant. Requests are paced with an 800 ms debounce and
a 1200 ms throttle to limit repeated inference while typing. Upstream currently
labels automatic suggestions experimental, so relevance and latency depend on
the selected model and local hardware.

Tool use still requires explicit permission prompts, generated diffs are not
auto-applied, access to Git-ignored files is disabled, and prompt replay logging
is off.

The plugin's lazy.nvim build hook runs `:AvanteBuild` to download the
release-matched prebuilt native libraries. This avoids compiling Avante's Rust
workspace during plugin installation; `curl`, `tar`, and internet access are
required. Building from source remains available with
`:AvanteBuild source=true` and requires Rust/Cargo plus a native C toolchain.
The project does not install Ollama or operating-system packages for you.

### Optional: Python provider

Most Neovim editing features do not require the Python provider. It is only
needed by Python remote plugins and integrations that explicitly use it.

To opt in, open Neovim and run:

```vim
:DotfilesInstallPythonProvider
```

The command uses `python3` from Neovim's `PATH` (Python 3.9 or newer). It creates
a dedicated environment at `${stdpath("data")}/python3-venv`, upgrades `pip`,
installs `pynvim`, and verifies that both `pynvim` and `neovim` import correctly.
The validated environment replaces the previous one only after all steps pass;
a failed venv creation, package install, or import leaves the existing provider
environment untouched. The command does not install Python or system packages,
and it never invokes Homebrew, apt, or another OS package manager.

Restart Neovim after installation. The early `init.lua` setup selects this
interpreter automatically when it exists. A manually configured
`vim.g.python3_host_prog` takes precedence.

If you prefer to provision it from a shell, the equivalent manual fallback is:

```sh
PYTHON_VENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python3-venv"
python3 -m venv "$PYTHON_VENV"
"$PYTHON_VENV/bin/python" -m pip install --upgrade pip pynvim
```

Verify the selected interpreter with:

```vim
:lua print(vim.g.python3_host_prog or "automatic provider detection")
:checkhealth vim.provider
```

If the health report tries to launch a missing `pynvim-python` executable, the
automatic provider launcher is unavailable. Use the command above rather than
installing `pynvim` into a global Python environment just to silence the warning.

### Tree-sitter

This configuration uses the current `nvim-treesitter/main` API, not the
legacy `master` API. It requires:

- Neovim 0.12.6 or newer.
- Mason-managed `tree-sitter-cli` 0.27.2.
- `tar`, `curl`, and a C compiler on PATH to build parser libraries.

Mason installs the pinned `tree-sitter-cli` 0.27.2, Prettier, and
`js-debug-adapter` automatically on normal startup. The TypeScript and ESLint
language servers are ensured by Mason-LSPConfig. On first startup, the
Treesitter integration compiles only configured parsers that are missing;
existing parser libraries are preserved. The configured parsers are
updated when the locked `nvim-treesitter` plugin revision changes. Mason handles
npm-backed tool installation automatically; no manual global npm install or OS
package-manager command is needed. The dotfiles installer itself never uses
`sudo` or modifies OS packages.

Inspect Mason's status with `:Mason`, and check parser/CLI health with
`:checkhealth nvim-treesitter`. From inside Neovim, `:TSInstall` installs a
parser and `:TSUpdate` updates installed parsers. If automatic setup reports
a missing CLI, verify that Mason's package is installed and that
`vim.fn.exepath("tree-sitter")` returns its executable path.

Highlighting uses Neovim's `vim.treesitter.start()` alongside Vim's
regex syntax highlighting, preserving the previous combined behavior.
Indentation uses the current Treesitter `indentexpr` (upstream describes this
feature as experimental). Any installed parser with matching highlight or
indent queries is configured when its filetype opens, including parsers added
manually with `:TSInstall`; the 41 parsers in the managed list are installed
and updated automatically. `<leader>V` selects/expands the current syntax node
and `<BS>` contracts the selection to its child node. Rainbow delimiters and
HTML/JSX/TSX autotagging use their standalone plugins.

Go buffers also use the standalone `nvim-treesitter-textobjects/main` plugin:
`af`/`if` select functions, `ac`/`ic` select type declarations, and
`]]`, `][`, `[[`, `[]` navigate function boundaries. These mappings use
the plugin's current `setup()` API; go.nvim's legacy textobject hook is disabled
because it depends on the removed `nvim-treesitter.configs` module. Go.nvim
itself remains enabled for Go tooling, LSP and commands.

The old `highlight_definitions` refactor extension was removed with the
legacy API. The current upstream rewrite exposes locals queries but does not
provide a maintained equivalent for that feature, so the configuration does
not pretend that LSP semantic tokens or reference navigation are the same
behavior.

### Updating installed plugins

Run `:Lazy update` normally. Before lazy.nvim checks out plugin updates, this
configuration temporarily removes only untracked `doc/tags` files generated by
its `:helptags` task. If an upstream plugin begins tracking that path, Git can
then check out the new revision. The post-update hook keeps the new upstream
file or regenerates the help index for plugins that were not updated. Tracked
`doc/tags` files and all other untracked files are preserved.

This preflight does not hide or delete arbitrary local plugin changes. When an
update still reports a modified file, inspect that exact path before deciding
whether to keep, restore, or migrate it.

### Interpreting optional health warnings

A `:checkhealth` report is not a list of system packages that must all be
installed. For example, Git already satisfies Diffview's VCS requirement, so
missing Mercurial is not actionable. Composer/PHP/Julia and the Perl provider
are only relevant when using the matching ecosystem or provider. Neorg key
conflicts, WhichKey overlap/deprecation warnings, and unknown LSP filetypes are
configuration issues rather than missing executables.

If `:checkhealth vim.pack` reports an existing package directory without a
lockfile while this configuration uses lazy.nvim, inspect the directory and
identify its owner before changing or deleting it. The installer does not
remove plugin data directories.

### Troubleshooting and validation

If plugin help tags ever become stale or a plugin's help topic cannot be found,
rebuild them manually from inside Neovim:

```vim
:helptags ALL
```

This is intentionally not run on every startup; rebuilding every help directory
on every launch adds work even when no plugin documentation has changed.

Run the headless smoke test from the repository root:

```sh
bash ./scripts/test-nvim-headless.sh
```

It creates a temporary HOME and XDG directories, installs the config there,
restores the locked plugin versions, and starts Neovim headlessly. It does not
touch your real Neovim or Emacs configuration.

For issues that only happen on your Mac (font rendering, clipboard integration,
terminal behavior, and perceived typing latency), a local interactive check is
still required.

## Emacs

Install only the Emacs configuration with:

```sh
bash ./install.sh --emacs
```

Install both editor configurations with:

```sh
bash ./install.sh --all
```

Existing `.emacs` and `.emacs.d` targets are backed up before replacement.
