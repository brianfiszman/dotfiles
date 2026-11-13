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

for required_command in "$NVIM_BIN" git find grep tee; do
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

# Validate the requested workspace before creating HOME/XDG directories in it.
# Subsequent restore/startup invocations intentionally reuse the populated workspace.
if [[ "$PHASE" == "prepare" || "$PHASE" == "all" ]]; then
  if [[ -e "$WORK_DIR" && ! -d "$WORK_DIR" ]]; then
    printf 'Error: NVIM_TEST_DIR exists but is not a directory: %s\n' "$WORK_DIR" >&2
    exit 1
  fi
  if [[ -d "$WORK_DIR" ]] && [[ -n "$(find "$WORK_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    printf 'Error: NVIM_TEST_DIR must be empty before the prepare phase: %s\n' "$WORK_DIR" >&2
    exit 1
  fi
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
  local -a nvim_args=(--headless)
  local startup_verbose_file="$WORK_DIR/startup-verbose.log"
  local startup_timing_file="$WORK_DIR/startup-startuptime.log"

  # A timeout during normal startup is not actionable without knowing which
  # scripts/functions were reached. Keep Neovim's own startup profile and
  # verbose trace as separate artifacts; do not alter plugin loading behavior.
  if [[ "$label" == "startup" ]]; then
    nvim_args+=(--startuptime "$startup_timing_file" "-V12$startup_verbose_file")
    printf '[startup] Diagnostic timing: %s\n' "$startup_timing_file"
    printf '[startup] Diagnostic trace: %s\n' "$startup_verbose_file"
  fi

  printf '\n[%s] Starting Neovim headless (limit: %s).\n' "$label" "$time_limit"
  printf '[%s] Live output follows; the full log is saved to %s\n' "$label" "$log_file"

  # Stream output to the Actions console while preserving a complete log file.
  # Capture PIPESTATUS explicitly so timeout/Neovim and tee failures stay distinct.
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout --signal=TERM --kill-after=30s "$time_limit" \
      "$NVIM_BIN" "${nvim_args[@]}" -u "$NVIM_CONFIG/init.lua" "$@" 2>&1 | tee "$log_file"
    pipeline_status=("${PIPESTATUS[@]}")
  else
    printf '[%s] GNU timeout is unavailable; running without a per-phase deadline. Install GNU coreutils for bounded local runs.\n' "$label"
    "$NVIM_BIN" "${nvim_args[@]}" -u "$NVIM_CONFIG/init.lua" "$@" 2>&1 | tee "$log_file"
    pipeline_status=("${PIPESTATUS[@]}")
  fi
  set -e

  command_status="${pipeline_status[0]:-1}"
  tee_status="${pipeline_status[1]:-1}"
  printf '[%s] Finished after %ss (Neovim/timeout exit: %s; log writer exit: %s).\n' \
    "$label" "$((SECONDS - start_time))" "$command_status" "$tee_status"

  if ((command_status == 124 || command_status == 137)); then
    printf 'Error: %s exceeded its %s time limit. The live output above and saved log identify the last visible operation.\n' \
      "$label" "$time_limit" >&2
    tail -n 80 "$log_file" >&2 || true
    if [[ "$label" == "startup" ]]; then
      printf '\\n--- Neovim startup verbose trace (last 120 lines) ---\\n' >&2
      tail -n 120 "$startup_verbose_file" >&2 || true
      printf '\\n--- Neovim startup timing profile (last 120 lines) ---\\n' >&2
      tail -n 120 "$startup_timing_file" >&2 || true
    fi
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

  # Neovim can report Lua/Vimscript errors while still returning exit status 0.
  # The verbose trace captures messages that do not reach stdout/stderr.
  if grep -Eiq 'Error detected while processing|E[0-9]{3}:|Error executing lua|Failed to run .*config|module .+ not found' "$log_file"; then
    printf 'Error: Neovim reported an error during %s. Last 80 log lines follow:\n' "$label" >&2
    tail -n 80 "$log_file" >&2
    return 1
  fi

  if [[ "$label" == "startup" ]]; then
    local missing_neorg_parser
    missing_neorg_parser="$(grep -Ei 'norg(_meta)? treesitter parser was not found' "$log_file" || true)"
    if [[ -n "$missing_neorg_parser" ]]; then
      printf 'Error: Neorg could not discover its Treesitter parsers during startup:\n%s\n' "$missing_neorg_parser" >&2
      return 1
    fi
  fi

  # Some plugin build hooks report failed external-tool installs through
  # vim.notify(..., ERROR) without returning a non-zero Neovim exit status.
  # Treat these as failed restore attempts rather than accepting a false-green.
  if [[ "$label" == "plugin-restore" ]]; then
    local failed_tool_installs
    failed_tool_installs="$(grep -Ei 'Vim:install [^[:space:]]+ failed:' "$log_file" || true)"
    if [[ -n "$failed_tool_installs" ]]; then
      printf 'Error: a configured plugin build hook failed to install an external tool:\n%s\n' "$failed_tool_installs" >&2
      return 1
    fi
  fi

  if [[ "$label" == "startup" && -s "$startup_verbose_file" ]]; then
    local unexpected_vim_errors
    unexpected_vim_errors="$(grep -E 'E[0-9]{3}:' "$startup_verbose_file" \
      | grep -Fv 'E216: No such group or event: FileExplorer *' || true)"
    if [[ -n "$unexpected_vim_errors" ]]; then
      printf 'Error: Neovim reported Vimscript errors in its startup trace:\n%s\n' "$unexpected_vim_errors" >&2
      printf 'Full trace: %s\n' "$startup_verbose_file" >&2
      return 1
    fi
    if grep -Fq 'E216: No such group or event: FileExplorer *' "$startup_verbose_file"; then
      printf '[startup] Note: ignored NvimTree 1.18.0 compatibility noise from its silent FileExplorer autocmd cleanup.\n'
    fi
  fi

  printf 'Passed: %s\n' "$label"
}

prepare() {
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
    "+lua assert(package.loaded['lazy'], 'lazy.nvim did not load')" \
    "+lua assert(#vim.api.nvim_get_runtime_file('parser/norg.so', true) > 0, 'Neorg norg parser is missing from runtimepath')" \
    "+lua assert(#vim.api.nvim_get_runtime_file('parser/norg_meta.so', true) > 0, 'Neorg norg_meta parser is missing from runtimepath')" \
    "+lua assert(pcall(vim.treesitter.language.add, 'norg'), 'Neorg norg parser could not be loaded')" \
    "+lua assert(pcall(vim.treesitter.language.add, 'norg_meta'), 'Neorg norg_meta parser could not be loaded')" \
    "+qa!"

  printf '\n[behavior] Verifying Go tooling loads only for Go-related filetypes.\n'
  run_nvim "go-lazy-loading-go" "$NVIM_STARTUP_TIMEOUT" \
    "+lua assert(package.loaded['go'] == nil, 'go.nvim loaded during an unrelated startup')" \
    "+lua vim.api.nvim_exec_autocmds('CmdlineEnter', { modeline = false })" \
    "+lua assert(package.loaded['go'] == nil, 'go.nvim loaded on CmdlineEnter in a non-Go buffer')" \
    "+setfiletype go" \
    "+lua assert(package.loaded['go'] ~= nil, 'go.nvim did not load for the Go filetype')" \
    "+lua assert(vim.fn.exists(':GoBuild') == 2, 'GoBuild command is missing after Go plugin load')" \
    "+qa!"

  run_nvim "go-lazy-loading-gomod" "$NVIM_STARTUP_TIMEOUT" \
    "+lua assert(package.loaded['go'] == nil, 'go.nvim loaded before the go.mod filetype')" \
    "+setfiletype gomod" \
    "+lua assert(package.loaded['go'] ~= nil, 'go.nvim did not load for the go.mod filetype')" \
    "+lua assert(vim.fn.exists(':GoBuild') == 2, 'GoBuild command is missing for go.mod buffers')" \
    "+qa!"
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
