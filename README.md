# Dotfiles

Personal shell, terminal, editor, and development-tool configuration.

## Neovim

The Neovim configuration lives in `.config/nvim` and uses **lazy.nvim**. The
first Neovim launch bootstraps lazy.nvim from Git; you do not need to install
dein.vim or run a manual plugin-manager command.

### Requirements

- Neovim 0.11 or newer.
- Git (used by lazy.nvim to download plugins).
- Internet access on the first launch.
- A terminal with a Nerd Font is recommended for icons, but the font is not
  required to start Neovim.

System packages and optional command-line tools used by individual plugins
(such as ripgrep, formatters, language servers, and debuggers) are installed
separately. The dotfiles installer does not use `sudo` or modify OS packages.

The Go plugin does not bulk-install its optional helper binaries during setup.
Open a Go file and run `:GoInstallBinaries` when you want the full toolset.

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

### Optional: Python provider

Most editing features do not require Neovim's Python provider. A few plugins
and Python integrations may use it. To create a dedicated environment without
committing or reusing a machine-specific virtualenv, run:

```sh
PYTHON_VENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python3-venv"
python3 -m venv "$PYTHON_VENV"
"$PYTHON_VENV/bin/python" -m pip install --upgrade pip pynvim
```

On the next launch, Neovim automatically uses this interpreter when it exists.
A manually configured `vim.g.python3_host_prog` takes precedence. Verify it
inside Neovim with:

```vim
:checkhealth provider
```

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
