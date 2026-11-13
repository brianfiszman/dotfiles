#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME:-$(cd ~ && pwd)}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$USER_HOME/.config}"

INSTALL_NVIM=0
INSTALL_EMACS=0
DRY_RUN=0
TARGET_SELECTED=0

usage() {
  cat <<'USAGE'
Usage: bash ./install.sh [--nvim] [--emacs] [--all] [--dry-run]

Install this repository's configuration without deleting the current setup.

Options:
  --nvim       Install only the Neovim configuration (the default).
  --emacs      Install only the Emacs configuration.
  --all        Install both Neovim and Emacs configurations.
  --dry-run    Show what would happen without changing any files.
  -h, --help   Show this help.

Existing configuration directories/files are moved to timestamped backups
before the new files are installed. The installer does not install system
packages and never invokes sudo, apt, or pacman.
USAGE
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name="$1"
  local purpose="$2"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    die "Missing '$command_name'. $purpose"
  fi
}

while (($#)); do
  case "$1" in
    --nvim)
      INSTALL_NVIM=1
      TARGET_SELECTED=1
      ;;
    --emacs)
      INSTALL_EMACS=1
      TARGET_SELECTED=1
      ;;
    --all)
      INSTALL_NVIM=1
      INSTALL_EMACS=1
      TARGET_SELECTED=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown option: $1"
      ;;
  esac
  shift
done

# Keep the common command-line experience simple: no target means Neovim only.
if ((TARGET_SELECTED == 0)); then
  INSTALL_NVIM=1
fi

backup_existing_target() {
  local target="$1"
  local timestamp backup suffix

  BACKUP_PATH=""
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  timestamp="$(date '+%Y%m%d-%H%M%S')"
  backup="${target}.backup.${timestamp}"
  suffix=1
  while [[ -e "$backup" || -L "$backup" ]]; do
    backup="${target}.backup.${timestamp}.${suffix}"
    suffix=$((suffix + 1))
  done

  mv "$target" "$backup"
  BACKUP_PATH="$backup"
}

install_directory() {
  local source="$1"
  local target="$2"
  local parent staging backup

  [[ -d "$source" ]] || die "Configuration source not found: $source"
  parent="$(dirname "$target")"

  if ((DRY_RUN)); then
    printf 'Would install directory: %s\n' "$source"
    printf '  -> %s\n' "$target"
    printf 'Would exclude generated environment: %s/venv\n' "$source"
    if [[ -e "$target" || -L "$target" ]]; then
      printf 'Would back up existing target before replacement.\n'
    fi
    return 0
  fi

  mkdir -p "$parent"
  staging="$(mktemp -d "$parent/.dotfiles-install.XXXXXX")"

  # Copy into a staging directory first. Exclude the generated, machine-specific
  # virtualenv so a fresh installation never receives another machine's Python.
  if ! tar -C "$source" --exclude='./venv' -cf - . | tar -C "$staging" -xf -; then
    rm -rf "$staging"
    die "Could not stage configuration from $source"
  fi

  backup_existing_target "$target"
  backup="$BACKUP_PATH"

  if ! mv "$staging" "$target"; then
    rm -rf "$staging"
    if [[ -n "$backup" ]]; then
      mv "$backup" "$target" || true
    fi
    die "Could not install $target; previous configuration restore was attempted"
  fi

  printf 'Installed: %s\n' "$target"
  if [[ -n "$backup" ]]; then
    printf 'Previous configuration backed up to: %s\n' "$backup"
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  local parent staging backup

  [[ -f "$source" ]] || die "Configuration source not found: $source"
  parent="$(dirname "$target")"

  if ((DRY_RUN)); then
    printf 'Would install file: %s\n' "$source"
    printf '  -> %s\n' "$target"
    if [[ -e "$target" || -L "$target" ]]; then
      printf 'Would back up existing target before replacement.\n'
    fi
    return 0
  fi

  mkdir -p "$parent"
  staging="$(mktemp "$parent/.dotfiles-install.XXXXXX")"
  if ! cp -p "$source" "$staging"; then
    rm -f "$staging"
    die "Could not stage file $source"
  fi

  backup_existing_target "$target"
  backup="$BACKUP_PATH"

  if ! mv "$staging" "$target"; then
    rm -f "$staging"
    if [[ -n "$backup" ]]; then
      mv "$backup" "$target" || true
    fi
    die "Could not install $target; previous file restore was attempted"
  fi

  printf 'Installed: %s\n' "$target"
  if [[ -n "$backup" ]]; then
    printf 'Previous file backed up to: %s\n' "$backup"
  fi
}

if ((INSTALL_NVIM)); then
  if ((DRY_RUN == 0)); then
    require_command nvim "Install Neovim before installing its configuration."
    require_command git "Git is required for lazy.nvim to bootstrap on first launch."
    require_command tar "tar is required to stage the configuration safely."
  fi
  install_directory "$SCRIPT_DIR/.config/nvim" "$XDG_CONFIG_HOME/nvim"
fi

if ((INSTALL_EMACS)); then
  install_file "$SCRIPT_DIR/.emacs" "$USER_HOME/.emacs"
  install_directory "$SCRIPT_DIR/.emacs.d" "$USER_HOME/.emacs.d"
fi

if ((DRY_RUN)); then
  printf '\nDry run complete. No files were changed.\n'
else
  printf '\nDone. Existing files were preserved in timestamped backups when present.\n'
  if ((INSTALL_NVIM)); then
    printf 'Start Neovim with: nvim\n'
    printf 'On first launch, init.lua bootstraps lazy.nvim and installs the declared plugins.\n'
  fi
fi
