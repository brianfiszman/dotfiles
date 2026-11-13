#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_HOME="$(mktemp -d)"
LOG_DIR="$TEMP_HOME/logs"
CONFIG_HOME="$TEMP_HOME/.config"
NVIM_CONFIG="$CONFIG_HOME/nvim"

cleanup() {
  rm -rf -- "$TEMP_HOME"
}
trap cleanup EXIT

fail() {
  printf 'Smoke test failed: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || fail "Git is required."
command -v nvim >/dev/null 2>&1 || fail "Neovim 0.11+ is required."
command -v bash >/dev/null 2>&1 || fail "Bash is required."

NVIM_VERSION="$(nvim --version | head -n 1)"
printf 'Using %s\n' "$NVIM_VERSION"

mkdir -p "$LOG_DIR" "$TEMP_HOME/.local/share" "$TEMP_HOME/.cache" "$TEMP_HOME/.local/state"

export HOME="$TEMP_HOME"
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$TEMP_HOME/.local/share"
export XDG_CACHE_HOME="$TEMP_HOME/.cache"
export XDG_STATE_HOME="$TEMP_HOME/.local/state"
export NVIM_CONFIG

run_and_check() {
  local label="$1"
  shift
  local log_file="$LOG_DIR/$label.log"

  printf '\n%s\n' "$label"
  if ! "$@" >"$log_file" 2>&1; then
    cat "$log_file" >&2
    fail "$label returned a non-zero exit code."
  fi

  if grep -E 'Error detected while processing|E[0-9]+:|Failed to run.*config|module .+ not found|attempt to index' "$log_file"; then
    cat "$log_file" >&2
    fail "$label reported a Neovim/Lua startup error."
  fi
  cat "$log_file"
}

printf '\n[1/4] Checking installer dry-run and backup behavior\n'
mkdir -p "$NVIM_CONFIG"
printf 'keep this local setting\n' > "$NVIM_CONFIG/local-only.txt"
"$REPO_ROOT/install.sh" --nvim --dry-run
[[ -f "$NVIM_CONFIG/local-only.txt" ]] || fail "Dry-run changed the existing config."

"$REPO_ROOT/install.sh" --nvim
[[ -f "$NVIM_CONFIG/init.lua" ]] || fail "Installer did not create init.lua."
[[ ! -e "$NVIM_CONFIG/venv" ]] || fail "Installer copied the machine-specific Python virtualenv."
[[ ! -e "$NVIM_CONFIG/local-only.txt" ]] || fail "Installer did not replace the config directory."

BACKUP_FILE="$(find "$XDG_STATE_HOME/dotfiles/backups" -name local-only.txt -print -quit)"
[[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]] || fail "Installer did not preserve the previous config in a backup."
[[ ! -e "$HOME/.emacs" && ! -e "$HOME/.emacs.d" ]] || fail "Default install unexpectedly changed Emacs files."

printf '\n[2/4] Checking Lua syntax in the installed config\n'
run_and_check "lua-syntax" nvim --headless -u NONE \
  -c "lua local files = vim.fn.globpath(vim.env.NVIM_CONFIG, '**/*.lua', false, true); table.insert(files, vim.env.NVIM_CONFIG .. '/init.lua'); for _, file in ipairs(files) do local chunk, err = loadfile(file); assert(chunk, file .. ': ' .. tostring(err)) end" \
  +qa

printf '\n[3/4] Installing/synchronizing plugins from lazy-lock.json\n'
run_and_check "lazy-sync" nvim --headless -u "$NVIM_CONFIG/init.lua" "+Lazy! sync" +qa

printf '\n[4/4] Starting Neovim headlessly with the installed plugins\n'
run_and_check "headless-startup" nvim --headless -u "$NVIM_CONFIG/init.lua" \
  -c "lua assert(vim.g.mapleader == ' ', 'mapleader should be Space')" +qa

printf '\nHeadless Neovim smoke test passed.\n'
