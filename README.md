# Dotfiles

Personal configuration for Neovim, Emacs, the shell, and other tools.

## Neovim setup

**Requirements:** Git and Neovim 0.11 or newer.

From the cloned repository, run:

```bash
./install.sh
```

The default installs only the Neovim configuration at `$XDG_CONFIG_HOME/nvim` (or `~/.config/nvim` when `XDG_CONFIG_HOME` is not set).

On first launch, `init.lua` bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim). lazy.nvim then installs the plugins declared by this config. To install/synchronize them explicitly from the terminal:

```bash
./install.sh --nvim --sync-plugins
```

There is no dein.vim step and no `:call dein#install()` command.

### Safe installation

The installer does not use `sudo`, install OS packages, or delete your active configuration. When a target already exists, it is moved to a timestamped backup under:

```
~/.local/state/dotfiles/backups/
```

You can preview actions without changing files:

```bash
./install.sh --dry-run
```

The repository's checked-in Neovim virtual environment is excluded from installation because Python environments contain machine-specific executables. For Python support, install `pynvim` into the Python environment Neovim should use, then check it with `:checkhealth provider`.

## Emacs setup (optional)

The default command does not change Emacs files. To install the Emacs configuration:

```bash
./install.sh --emacs
```

To install both Neovim and Emacs configurations:

```bash
./install.sh --all
```

Existing Emacs files are backed up before replacement, just like the Neovim config.

## Testing the Neovim config

Run the isolated headless smoke test locally:

```bash
scripts/neovim-smoke-test.sh
```

It creates a temporary HOME and XDG directories, installs the config there, syncs lazy.nvim plugins, and launches Neovim headlessly. It does not change your real Neovim setup.

GitHub Actions runs the same check for pull requests and pushes to `master`.

## Supported environment

- Neovim 0.11+
- Git
- Linux and macOS are the intended environments.
- Optional tools (formatters, linters, language servers, debuggers) are installed separately and are only needed for the languages/workflows that use them.
