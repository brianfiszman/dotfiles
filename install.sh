#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"
INSTALL_NVIM=true
INSTALL_EMACS=false
DRY_RUN=false
SYNC_PLUGINS=false
BACKUP_DIR="$HOME/.local/state/dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
TEMP_DIR=""

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Install this repository's dotfiles without deleting existing user data.

Options:
  --nvim            Install the Neovim config (default)
  --emacs           Install the Emacs config only
  --all             Install Neovim and Emacs configs
  --sync-plugins    After installing Neovim, run lazy.nvim sync
  --dry-run         Print actions without changing files
  -h, --help        Show this help

Examples:
  ./install.sh
  ./install.sh --nvim --sync-plugins
  ./install.sh --emacs
  ./install.sh --all --dry-run

Existing config paths are moved to a timestamped backup under:
  ~/.local/state/dotfiles/backups/
USAGE
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf -- "$TEMP_DIR"
  fi
}
trap cleanup EXIT

while (($#)); do
  case "$1" in
    --nvim)
      INSTALL_NVIM=true
      INSTALL_EMACS=false
      ;;
    --emacs)
      INSTALL_NVIM=false
      INSTALL_EMACS=true
      ;;
    --all)
      INSTALL_NVIM=true
      INSTALL_EMACS=true
      ;;
    --sync-plugins)
      SYNC_PLUGINS=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1 (use --help to see available options)"
      ;;
  esac
  shift
done

[[ "$CONFIG_HOME" = /* ]] || die "XDG_CONFIG_HOME must be an absolute path."
command -v git >/dev/null 2>&1 || die "Git is required by lazy.nvim. Install Git and run this script again."

if "$SYNC_PLUGINS"; then
  "$INSTALL_NVIM" || die "--sync-plugins requires a Neovim installation."
  command -v nvim >/dev/null 2>&1 || die "Neovim is required for --sync-plugins. Install Neovim or omit this option."
fi

install_path() {
  local source_path="$1"
  local target_path="$2"
  local label="$3"
  local parent_path
  local staged_path
  local backup_path=""

  [[ -e "$source_path" ]] || die "Source path does not exist: $source_path"
  parent_path="$(dirname -- "$target_path")"

  if "$DRY_RUN"; then
    printf 'Would install %s\n  from: %s\n  to:   %s\n' "$label" "$source_path" "$target_path"
    if [[ -e "$target_path" || -L "$target_path" ]]; then
      printf '  backup: %s/%s\n' "$BACKUP_DIR" "$label"
    fi
    return
  fi

  mkdir -p -- "$parent_path"
  TEMP_DIR="$(mktemp -d "$parent_path/.dotfiles-install.XXXXXX")"
  staged_path="$TEMP_DIR/$(basename -- "$target_path")"

  if [[ -d "$source_path" ]]; then
    mkdir -p -- "$staged_path"
    cp -a -- "$source_path/." "$staged_path/"
    # A checked-in virtualenv is machine-specific and must never be installed.
    if [[ "$label" == "nvim" ]]; then
      rm -rf -- "$staged_path/venv"
    fi
  else
    cp -a -- "$source_path" "$staged_path"
  fi

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    mkdir -p -- "$BACKUP_DIR"
    backup_path="$BACKUP_DIR/$label"
    [[ ! -e "$backup_path" && ! -L "$backup_path" ]] || die "Backup already exists: $backup_path"
    mv -- "$target_path" "$backup_path"
  fi

  if ! mv -- "$staged_path" "$target_path"; then
    if [[ -n "$backup_path" && ( -e "$backup_path" || -L "$backup_path" ) ]]; then
      mv -- "$backup_path" "$target_path"
    fi
    die "Could not install $label at $target_path. The previous config was restored when possible."
  fi

  rm -rf -- "$TEMP_DIR"
  TEMP_DIR=""
  printf 'Installed %s: %s\n' "$label" "$target_path"
  if [[ -n "$backup_path" ]]; then
    printf 'Previous config backed up to: %s\n' "$backup_path"
  fi
}

if "$INSTALL_NVIM"; then
  install_path "$REPO_ROOT/.config/nvim" "$CONFIG_HOME/nvim" "nvim"
fi

if "$INSTALL_EMACS"; then
  install_path "$REPO_ROOT/.emacs" "$HOME/.emacs" "emacs-file"
  install_path "$REPO_ROOT/.emacs.d" "$HOME/.emacs.d" "emacs-dir"
fi

if "$SYNC_PLUGINS" && ! "$DRY_RUN"; then
  printf 'Syncing Neovim plugins with lazy.nvim...\n'
  XDG_CONFIG_HOME="$CONFIG_HOME" nvim --headless -u "$CONFIG_HOME/nvim/init.lua" "+Lazy! sync" +qa
fi

if "$DRY_RUN"; then
  printf 'Dry run complete. No files were changed.\n'
else
  printf 'Setup complete. Start Neovim with: nvim\n'
  if "$INSTALL_NVIM" && ! "$SYNC_PLUGINS"; then
    printf 'lazy.nvim will install the configured plugins on first launch.\n'
  fi
fi
