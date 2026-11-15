# Dotfiles

Personal shell, terminal, editor, and development-tool configuration.

## Neovim

The Neovim configuration lives in `.config/nvim` and uses **lazy.nvim**. The
first Neovim launch bootstraps lazy.nvim from Git; you do not need to install
dein.vim or run a manual plugin-manager command.

### Requirements

- Neovim 0.11.3 or newer.
- Git (used by lazy.nvim to download plugins).
- Internet access on the first launch.
- A terminal with a Nerd Font is recommended for icons, but the font is not
  required to start Neovim.

System packages and optional command-line tools used by individual plugins
(such as ripgrep, formatters, language servers, and debuggers) are installed
separately. The dotfiles installer does not use `sudo` or modify OS packages.

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
Use `:Lazy` inside Neovim to inspect plugin status.

If lazy.nvim cannot be downloaded, Neovim displays an actionable error. Check
that Git is installed and that the network can reach GitHub, then restart Neovim.

### Editing

- In Normal mode, **Ctrl+F** runs the shared `:Format` command through Conform.
  For JavaScript and TypeScript it selects `prettierd` when available, otherwise
  `prettier`, and follows the project's Prettier configuration.
- LuaLS plugin type libraries are supplied by lazydev, which loads only for Lua buffers.
- ESLint diagnostics for JavaScript/TypeScript come from the ESLint language
  server. Its `LspEslintFixAll` action still runs before saving an attached buffer.
- Use `K` for symbol documentation, `<leader>DF` for the diagnostic under the
  cursor, and `[d` / `]d` to move between diagnostics.

### Optional: Python provider

Most Neovim editing features do not require the Python provider. It is only
needed by Python remote plugins and integrations that explicitly use it.

This configuration prefers a dedicated environment at
`${stdpath("data")}/python3-venv/bin/python` when it exists. Create it with
the same Python 3 interpreter available on the target machine:

```sh
PYTHON_VENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python3-venv"
python3 -m venv "$PYTHON_VENV"
"$PYTHON_VENV/bin/python" -m pip install --upgrade pip pynvim
```

Restart Neovim after installation. The early `init.lua` setup selects this
interpreter automatically when the executable exists. A manually configured
`vim.g.python3_host_prog` takes precedence.

Verify the selected interpreter with:

```vim
:lua print(vim.g.python3_host_prog or "automatic provider detection")
:checkhealth vim.provider
```

If the health report tries to launch a missing `pynvim-python` executable, the
automatic provider launcher is unavailable. Creating the dedicated venv above
gives this configuration an explicit interpreter path. Do not install
`pynvim` into a global Python environment just to silence the warning.

### Optional: Tree-sitter CLI

The current configuration uses the legacy `nvim-treesitter` API. Its
healthcheck says the `tree-sitter` executable is only needed for
`:TSInstallFromGrammar`; it is not required for ordinary `:TSInstall` or for
the parser binaries already installed by this configuration.

When grammar regeneration is needed, install the CLI from inside Neovim through
Mason:

```vim
:MasonInstall tree-sitter-cli
```

Verify that Neovim can find it:

```vim
:lua print(vim.fn.executable("tree-sitter"))
:checkhealth nvim-treesitter
:checkhealth lspsaga
```

A result of `1` means the executable is on Neovim's PATH. This is an optional
Mason-managed tool, not a prerequisite for JavaScript/TypeScript indentation.
Do not install it with a system package manager merely to make ordinary parser
installation work.

### Existing Treesitter installations on Neovim 0.12

The compatibility layer is restricted to the legacy `nvim-treesitter` revision
pinned in `lazy-lock.json`. Its plugin spec is also marked `pin = true`, so
`:Lazy update` does not silently advance this API-dependent plugin before a
separately tested migration. It adapts query capture lists in memory, so it does
not leave modifications in the plugin's Git checkout.

When moving from the previous dotfiles revision, the next normal startup
recognizes and reverses only the exact compatibility patch that the earlier
version applied to `query_predicates.lua`. It refuses to overwrite unrelated
local edits. The query handlers are then registered through the in-memory
adapter before Treesitter loads. No manual `:Lazy build`, plugin deletion, or
source editing is required.

### Updating installed plugins

Run `:Lazy update` normally. Before lazy.nvim checks out plugin updates, this
configuration removes only untracked `doc/tags` files generated by its
`:helptags` task. If an upstream plugin begins tracking that path, Git can
then check out the new revision. Tracked `doc/tags` files and all other
untracked files are preserved.

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
