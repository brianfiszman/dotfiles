#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_BIN="${NVIM_BIN:-nvim}"

if ! command -v "$NVIM_BIN" >/dev/null 2>&1; then
  printf "Error: Neovim executable not found: %s\n" "$NVIM_BIN" >&2
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  printf "Error: Git is required to bootstrap lazy.nvim.\n" >&2
  exit 1
fi

if [[ -n "${NVIM_TEST_DIR:-}" ]]; then
  WORK_DIR="$NVIM_TEST_DIR"
  mkdir -p "$WORK_DIR"
  CLEAN_WORK_DIR=0
else
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-nvim-smoke.XXXXXX")"
  CLEAN_WORK_DIR=1
fi

cleanup() {
  if ((CLEAN_WORK_DIR)); then
    rm -rf "$WORK_DIR"
  else
    printf 'Smoke-test files kept at: %s\n' "$WORK_DIR"
  fi
}
trap cleanup EXIT

# Every Neovim path is redirected into a disposable home. This test never reads
# or writes the developer's real ~/.config/nvim, plugin cache, or state files.
export HOME="$WORK_DIR/home"
export XDG_CONFIG_HOME="$WORK_DIR/config"
export XDG_DATA_HOME="$WORK_DIR/data"
export XDG_STATE_HOME="$WORK_DIR/state"
export XDG_CACHE_HOME="$WORK_DIR/cache"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

printf 'Testing Neovim: '
"$NVIM_BIN" --version | head -n 1

printf '\n[1/3] Installing dotfiles into an isolated HOME...\n'
bash "$REPO_ROOT/install.sh" --nvim

NVIM_CONFIG="$XDG_CONFIG_HOME/nvim"
[[ -f "$NVIM_CONFIG/init.lua" ]] || {
  printf 'Error: installer did not copy init.lua.\n' >&2
  exit 1
}
if [[ -e "$NVIM_CONFIG/venv" ]]; then
  printf 'Error: installer copied the machine-specific Python virtualenv.\n' >&2
  exit 1
fi

run_nvim() {
  local label="$1"
  shift
  local log_file="$WORK_DIR/$label.log"

  printf '\nRunning Neovim headless: %s\n' "$label"
  if ! "$NVIM_BIN" --headless -u "$NVIM_CONFIG/init.lua" "$@" >"$log_file" 2>&1; then
    printf '\nNeovim failed during %s. Output follows:\n' "$label" >&2
    cat "$log_file" >&2
    return 1
  fi

  # Neovim can log Lua/plugin errors while still returning exit status 0.
  if grep -Eiq 'Error detected while processing|E[0-9]{3}:|Error executing lua|Failed to run .*config|module .+ not found' "$log_file"; then
    printf '\nNeovim reported an error during %s. Output follows:\n' "$label" >&2
    cat "$log_file" >&2
    return 1
  fi

  printf 'Passed: %s\n' "$label"
}

printf '\n[2/3] Restoring the exact plugin versions from lazy-lock.json...\n'
run_nvim "plugin-restore" "+Lazy! restore" "+qa!"

printf '\n[3/3] Starting the installed configuration a second time...\n'
run_nvim "startup" "+lua assert(package.loaded['lazy'], 'lazy.nvim did not load')" "+qa!"

printf '\nHeadless smoke test passed.\n'
