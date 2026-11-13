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

If lazy.nvim cannot be downloaded, check that Git is installed and that the
network can reach GitHub, then restart Neovim.

### Troubleshooting and validation

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
