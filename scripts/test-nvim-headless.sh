#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_BIN="${NVIM_BIN:-nvim}"
PHASE="${1:-all}"
NVIM_RESTORE_TIMEOUT="${NVIM_RESTORE_TIMEOUT:-20m}"
NVIM_STARTUP_TIMEOUT="${NVIM_STARTUP_TIMEOUT:-5m}"

case "$PHASE" in
  all|prepare|restore|startup) ;;
  *)
    printf 'Usage: %s [all|prepare|restore|startup]\n' "$0" >&2
    exit 2
    ;;
esac

for required_command in "$NVIM_BIN" git find grep tee timeout; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Error: required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

if [[ -n "${NVIM_TEST_DIR:-}" ]]; then
  WORK_DIR="$NVIM_TEST_DIR"
  CLEAN_WORK_DIR=0
else
  if [[ "$PHASE" != "all" ]]; then
    printf 'Error: phases other than "all" require NVIM_TEST_DIR to persist state between invocations.\n' >&2
    exit 1
  fi
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-nvim-smoke.XXXXXX")"
  CLEAN_WORK_DIR=1
fi

mkdir -p "$WORK_DIR"
NVIM_CONFIG="$WORK_DIR/config/nvim"

cleanup() {
  if ((CLEAN_WORK_DIR)); then
    rm -rf -- "$WORK_DIR"
  else
    printf 'Smoke-test files and logs kept at: %s\n' "$WORK_DIR"
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

PREPARED_MARKER="$WORK_DIR/.prepared"
RESTORE_MARKER="$WORK_DIR/.restore-passed"

run_nvim() {
  local label="$1"
  local time_limit="$2"
  shift 2

  local log_file="$WORK_DIR/$label.log"
  local start_time="$SECONDS"
  local command_status=0
  local tee_status=0
  local -a pipeline_status=()

  printf '\n[%s] Starting Neovim headless (limit: %s).\n' "$label" "$time_limit"
  printf '[%s] Live output follows; the full log is saved to %s\n' "$label" "$log_file"

  # Stream output to the Actions console while preserving a complete log file.
  # Capture PIPESTATUS explicitly so timeout/Neovim and tee failures stay distinct.
  set +e
  timeout --signal=TERM --kill-after=30s "$time_limit" \
    "$NVIM_BIN" --headless -u "$NVIM_CONFIG/init.lua" "$@" 2>&1 | tee "$log_file"
  pipeline_status=("${PIPESTATUS[@]}")
  set -e

  command_status="${pipeline_status[0]:-1}"
  tee_status="${pipeline_status[1]:-1}"
  printf '[%s] Finished after %ss (Neovim/timeout exit: %s; log writer exit: %s).\n' \
    "$label" "$((SECONDS - start_time))" "$command_status" "$tee_status"

  if ((command_status == 124 || command_status == 137)); then
    printf 'Error: %s exceeded its %s time limit. The live output above and saved log identify the last visible operation.\n' \
      "$label" "$time_limit" >&2
    tail -n 80 "$log_file" >&2 || true
    return 124
  fi

  if ((command_status != 0)); then
    printf 'Error: Neovim failed during %s (exit %s). Last 80 log lines follow:\n' \
      "$label" "$command_status" >&2
    tail -n 80 "$log_file" >&2 || true
    return "$command_status"
  fi

  if ((tee_status != 0)); then
    printf 'Error: could not stream/write the %s log (tee exit %s).\n' "$label" "$tee_status" >&2
    return "$tee_status"
  fi

  # Neovim can report Lua/plugin errors while still returning exit status 0.
  if grep -Eiq 'Error detected while processing|E[0-9]{3}:|Error executing lua|Failed to run .*config|module .+ not found' "$log_file"; then
    printf 'Error: Neovim reported an error during %s. Last 80 log lines follow:\n' "$label" >&2
    tail -n 80 "$log_file" >&2
    return 1
  fi

  printf 'Passed: %s\n' "$label"
}

prepare() {
  if [[ -n "$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    printf 'Error: NVIM_TEST_DIR must be empty before the prepare phase: %s\n' "$WORK_DIR" >&2
    return 1
  fi

  printf '[prepare] Checking shell syntax...\n'
  bash -n "$REPO_ROOT/install.sh"
  bash -n "$REPO_ROOT/scripts/test-nvim-headless.sh"

  printf '[prepare] Testing Neovim: '
  "$NVIM_BIN" --version | sed -n '1p'

  # Seed an existing config so dry-run and backup behavior are tested, not assumed.
  mkdir -p "$XDG_CONFIG_HOME/nvim"
  printf 'keep-this-file\n' > "$XDG_CONFIG_HOME/nvim/install-test-sentinel"

  printf '\n[prepare] Verifying dry-run leaves the existing config untouched...\n'
  bash "$REPO_ROOT/install.sh" --dry-run
  grep -qx 'keep-this-file' "$XDG_CONFIG_HOME/nvim/install-test-sentinel"

  printf '\n[prepare] Installing dotfiles into the isolated HOME...\n'
  bash "$REPO_ROOT/install.sh" --nvim

  [[ -f "$NVIM_CONFIG/init.lua" ]] || {
    printf 'Error: installer did not copy init.lua.\n' >&2
    return 1
  }
  if [[ -e "$NVIM_CONFIG/venv" ]]; then
    printf 'Error: installer copied the machine-specific Python virtualenv.\n' >&2
    return 1
  fi
  if [[ -e "$HOME/.emacs" || -e "$HOME/.emacs.d" ]]; then
    printf 'Error: Neovim-only install unexpectedly changed Emacs configuration.\n' >&2
    return 1
  fi

  local backup_dir
  backup_dir="$(find "$XDG_CONFIG_HOME" -maxdepth 1 -type d -name 'nvim.backup.*' -print -quit)"
  if [[ -z "$backup_dir" ]] || ! grep -qx 'keep-this-file' "$backup_dir/install-test-sentinel"; then
    printf 'Error: existing Neovim config was not preserved in a backup.\n' >&2
    return 1
  fi

  touch "$PREPARED_MARKER"
  printf '[prepare] Passed. Isolated config is ready at %s\n' "$NVIM_CONFIG"
}

restore_plugins() {
  [[ -f "$PREPARED_MARKER" ]] || {
    printf 'Error: prepare phase has not completed for %s\n' "$WORK_DIR" >&2
    return 1
  }

  printf '[restore] Restoring the exact plugin revisions from lazy-lock.json.\n'
  printf '[restore] Configured plugin build hooks remain enabled; no CI-only plugin bypasses are used.\n'
  run_nvim "plugin-restore" "$NVIM_RESTORE_TIMEOUT" "+Lazy! restore" "+qa!"
  touch "$RESTORE_MARKER"
  printf '[restore] Locked plugin restore and configured build hooks passed.\n'
}

startup() {
  [[ -f "$RESTORE_MARKER" ]] || {
    printf 'Error: locked plugin restore has not completed for %s\n' "$WORK_DIR" >&2
    return 1
  }

  # The final process must exercise the same startup path as a normal user launch.
  unset DOTFILES_CI
  printf '[startup] Starting the installed configuration without CI-only flags.\n'
  run_nvim "startup" "$NVIM_STARTUP_TIMEOUT" \
    "+lua assert(package.loaded['lazy'], 'lazy.nvim did not load')" "+qa!"
}

case "$PHASE" in
  all)
    prepare
    restore_plugins
    startup
    ;;
  prepare)
    prepare
    ;;
  restore)
    restore_plugins
    ;;
  startup)
    startup
    ;;
esac

printf '\nHeadless Neovim smoke test passed (%s phase).\n' "$PHASE"
