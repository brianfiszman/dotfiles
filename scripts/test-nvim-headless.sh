#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_BIN="${NVIM_BIN:-nvim}"
PHASE="${1:-all}"
NVIM_RESTORE_TIMEOUT="${NVIM_RESTORE_TIMEOUT:-40m}"
NVIM_STARTUP_TIMEOUT="${NVIM_STARTUP_TIMEOUT:-30m}"
NVIM_TREESITTER_TIMEOUT="${NVIM_TREESITTER_TIMEOUT:-20m}"
NVIM_FOCUS_TIMEOUT="${NVIM_FOCUS_TIMEOUT:-45s}"
VIM_ERROR_CODE_PATTERN='E[0-9]{3,4}:'

case "$PHASE" in
  all|prepare|restore|startup) ;;
  *)
    printf 'Usage: %s [all|prepare|restore|startup]\n' "$0" >&2
    exit 2
    ;;
esac

for required_command in "$NVIM_BIN" git find grep tee script make curl tar python3; do
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
  local use_pty=0
  local use_focus_pty=0
  if [[ "$label" == "scrolling" ]]; then
    # Native mouse input needs an attached UI; a PTY-backed TUI gives the
    # integration test a real screen grid without manual interaction.
    # Mason and Tree-sitter can emit many startup notifications while their
    # first-use tools/parsers are provisioned. Never let the TUI pause on the
    # pager's -- More -- prompt while the synthetic input test is running.
    nvim_args=(--cmd "set nomore")
    use_pty=1
  elif [[ "$label" == checktime-focus-* ]]; then
    # Drive focus reports through Neovim's TUI parser using a real PTY master.
    nvim_args=()
    use_focus_pty=1
  fi
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

  if ((use_pty || use_focus_pty)); then
    printf '\n[%s] Starting Neovim in a PTY-backed TUI (limit: %s).\n' "$label" "$time_limit"
  else
    printf '\n[%s] Starting Neovim headless (limit: %s).\n' "$label" "$time_limit"
  fi
  printf '[%s] Live output follows; the full log is saved to %s\n' "$label" "$log_file"

  # Stream output to the Actions console while preserving a complete log file.
  # Capture PIPESTATUS explicitly so timeout/Neovim and tee failures stay distinct.
  local -a nvim_command
  if ((use_focus_pty)); then
    # Focus scenarios isolate native checktime behavior from Mason's
    # unrelated LSP package provisioning and its asynchronous UI notifications.
    nvim_command=(env DOTFILES_SKIP_MASON_LSP_INSTALL=1 python3 "$REPO_ROOT/scripts/run-nvim-focus-pty.py" -- "$NVIM_BIN" --cmd "set nomore" -u "$NVIM_CONFIG/init.lua" "$@")
  else
    nvim_command=("$NVIM_BIN" "${nvim_args[@]}" -u "$NVIM_CONFIG/init.lua" "$@")
  fi
  local pty_command=""
  if ((use_pty)); then
    printf -v pty_command '%q ' "${nvim_command[@]}"
  fi

  set +e
  if command -v timeout >/dev/null 2>&1; then
    if ((use_focus_pty)); then
      timeout --signal=TERM --kill-after=10s "$time_limit" \
        "${nvim_command[@]}" 2>&1 | tee "$log_file"
    elif ((use_pty)); then
      if [[ "${OSTYPE:-}" == darwin* ]]; then
        TERM=xterm-256color timeout --signal=TERM --kill-after=30s "$time_limit" \
          script -qeF /dev/null "${nvim_command[@]}" 2>&1 | tee "$log_file"
      else
        TERM=xterm-256color timeout --signal=TERM --kill-after=30s "$time_limit" \
          script -qefc "$pty_command" /dev/null 2>&1 | tee "$log_file"
      fi
    else
      timeout --signal=TERM --kill-after=30s "$time_limit" \
        "${nvim_command[@]}" 2>&1 | tee "$log_file"
    fi
    pipeline_status=("${PIPESTATUS[@]}")
  else
    printf '[%s] GNU timeout is unavailable; running without a per-phase deadline. Install GNU coreutils for bounded local runs.\n' "$label" >&2
    if ((use_focus_pty)); then
      "${nvim_command[@]}" 2>&1 | tee "$log_file"
    elif ((use_pty)); then
      if [[ "${OSTYPE:-}" == darwin* ]]; then
        TERM=xterm-256color script -qeF /dev/null "${nvim_command[@]}" 2>&1 | tee "$log_file"
      else
        TERM=xterm-256color script -qefc "$pty_command" /dev/null 2>&1 | tee "$log_file"
      fi
    else
      "${nvim_command[@]}" 2>&1 | tee "$log_file"
    fi
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
      printf '\n--- Neovim startup verbose trace (last 120 lines) ---\n' >&2
      tail -n 120 "$startup_verbose_file" >&2 || true
      printf '\n--- Neovim startup timing profile (last 120 lines) ---\n' >&2
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
  local error_scan_file="$log_file"
  if [[ "$label" == "scrolling" ]]; then
    # The PTY has no terminal emulator to answer Neovim's OSC 11 background
    # query. Ignore only this exact synthetic-terminal warning; all other
    # Vim/Lua errors remain fatal and the original log is preserved.
    error_scan_file="$WORK_DIR/scrolling-error-scan.log"
    grep -Fv -e "E1568: Terminal did not respond to DSR request for 'background' color" \
      -e "E216: No such group or event: FileExplorer *" \
      "$log_file" > "$error_scan_file" || true
  fi
  if grep -Eiq "Error detected while processing|Error in command line|${VIM_ERROR_CODE_PATTERN}|Error executing lua|vim\\.schedule callback|Invalid buffer id:|Failed to run .*config|module .+ not found" "$error_scan_file"; then
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
    unexpected_vim_errors="$(grep -E "$VIM_ERROR_CODE_PATTERN" "$startup_verbose_file" \
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
  printf '[prepare] Checking Vim error-code matcher...\n'
  local matcher_fixture="$WORK_DIR/vim-error-code-matcher.log"
  local matcher_result
  printf 'E12: too short\nE123: three digits\nE1234: four digits\nE12345: too long\n' > "$matcher_fixture"
  matcher_result="$(grep -E "$VIM_ERROR_CODE_PATTERN" "$matcher_fixture")"
  [[ "$matcher_result" == "$(printf 'E123: three digits\nE1234: four digits')" ]] || {
    printf 'Error: Vim error matcher did not recognize exactly three- and four-digit codes.\n' >&2
    printf 'Matched: %s\n' "$matcher_result" >&2
    return 1
  }

  printf '[prepare] Checking shell and Python helper syntax...\n'
  bash -n "$REPO_ROOT/install.sh"
  bash -n "$REPO_ROOT/scripts/test-nvim-headless.sh"
  PYTHONPYCACHEPREFIX="$WORK_DIR/pycache" python3 -m py_compile "$REPO_ROOT/scripts/run-nvim-focus-pty.py"

  local tracked_python_venv
  tracked_python_venv="$(git -C "$REPO_ROOT" ls-files -- .config/nvim/venv/)"
  if [[ -n "$tracked_python_venv" ]]; then
    printf 'Error: machine-local Python provider files must not be tracked:\n%s\n' "$tracked_python_venv" >&2
    return 1
  fi
  printf '[prepare] Passed: no machine-local Python virtualenv is tracked.\n'

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
  local -a restore_checks=("+Lazy! restore" "+lua local failures = {}; for name, plugin in pairs(require('lazy.core.config').plugins) do for _, task in ipairs(plugin._.tasks or {}) do if task.name == 'build' and task:has_errors() then table.insert(failures, name .. ': ' .. task:output(vim.log.levels.ERROR)) end end end; assert(#failures == 0, 'lazy.nvim build hook failures: ' .. table.concat(failures, '\n')); print('PASS: no lazy.nvim build task reported errors')")
  local verify_build_hooks="+lua local plugins = require('lazy.core.config').plugins; for _, name in ipairs({'LuaSnip', 'avante.nvim', 'nvim-treesitter'}) do local plugin = assert(plugins[name], 'missing build-hook plugin ' .. name); assert(plugin.build ~= nil, name .. ' has no configured build hook') end; assert(vim.g.dotfiles_treesitter_build_hook_ran == true, 'nvim-treesitter build hook did not execute'); print('PASS: configured build hooks exist and nvim-treesitter hook executed')"
  if [[ "${DOTFILES_PLUGIN_CACHE_HIT:-false}" == "true" ]]; then
    printf '[restore] Plugin cache hit; force-running every configured lazy.nvim build hook.\n'
    # A restored checkout is already at the locked revision, so lazy.nvim
    # correctly skips normal build hooks. Force them on cache hits to ensure
    # cached sources never become a substitute for actual build validation.
    restore_checks+=("+lua local config = require('lazy.core.config'); config.options.concurrency = 1; assert(config.options.concurrency == 1); print('PASS: forced plugin builds are serialized to avoid shared toolchain/cache races')")
    restore_checks+=("+Lazy! build all" "+lua local failures = {}; for name, plugin in pairs(require('lazy.core.config').plugins) do for _, task in ipairs(plugin._.tasks or {}) do if task.name == 'build' and task:has_errors() then table.insert(failures, name .. ': ' .. task:output(vim.log.levels.ERROR)) end end end; assert(#failures == 0, 'lazy.nvim build hook failures: ' .. table.concat(failures, '\\n')); print('PASS: no lazy.nvim build task reported errors')" "$verify_build_hooks")
  else
    restore_checks+=("$verify_build_hooks")
  fi
  restore_checks+=("+qa!")

  DOTFILES_SKIP_TREESITTER_PROVISIONING=1 \
    run_nvim "plugin-restore" "$NVIM_RESTORE_TIMEOUT" "${restore_checks[@]}"

  local luasnip_native_library="$XDG_DATA_HOME/nvim/lazy/LuaSnip/deps/luasnip-jsregexp.so"
  if [[ ! -s "$luasnip_native_library" ]]; then
    printf 'Error: LuaSnip native build artifact is missing: %s\n' "$luasnip_native_library" >&2
    return 1
  fi
  printf '[restore] LuaSnip native build artifact installed: %s\n' "$luasnip_native_library"

  # Avante's :AvanteBuild must leave release-matched native libraries in the
  # plugin Lua directory. This catches build-command failures that Neovim may
  # report through notifications without returning a non-zero exit code.
  local avante_lua_dir="$XDG_DATA_HOME/nvim/lazy/avante.nvim/lua"
  local avante_native_libraries
  if [[ ! -d "$avante_lua_dir" ]]; then
    printf 'Error: Avante Lua directory is missing after plugin restore: %s\n' "$avante_lua_dir" >&2
    return 1
  fi
  avante_native_libraries="$(find "$avante_lua_dir" -maxdepth 1 -type f -name 'avante_*.so' -print)"
  if [[ -z "$avante_native_libraries" ]]; then
    printf 'Error: Avante prebuilt native libraries were not installed in %s\n' "$avante_lua_dir" >&2
    return 1
  fi
  printf '[restore] Avante native libraries installed:\n%s\n' "$avante_native_libraries"

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

  local -a startup_checks=(
    "+lua assert(package.loaded['lazy'], 'lazy.nvim did not load')"
    "+lua assert(#vim.api.nvim_get_runtime_file('parser/norg.so', true) > 0, 'Neorg norg parser is missing from runtimepath')"
    "+lua assert(#vim.api.nvim_get_runtime_file('parser/norg_meta.so', true) > 0, 'Neorg norg_meta parser is missing from runtimepath')"
    "+lua assert(pcall(vim.treesitter.language.add, 'norg'), 'Neorg norg parser could not be loaded')"
    "+lua assert(pcall(vim.treesitter.language.add, 'norg_meta'), 'Neorg norg_meta parser could not be loaded')"
    "+lua assert(vim.wait(20 * 60 * 1000, function() return vim.g.dotfiles_treesitter_ready == true or vim.g.dotfiles_treesitter_error ~= nil end, 100), 'Mason did not finish current Treesitter setup'); assert(vim.g.dotfiles_treesitter_error == nil, 'Treesitter setup failed: ' .. tostring(vim.g.dotfiles_treesitter_error))"
  )

  startup_checks+=("+qa!")

  run_nvim "startup" "$NVIM_STARTUP_TIMEOUT" "${startup_checks[@]}"

  printf '\n[behavior] Verifying Avante lazy-loading, local provider configuration, and safe defaults.\n'
  run_nvim "avante-lazy-loading" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/avante-lazy-loading.lua" \
    "+qa!"

  printf '\n[behavior] Verifying real terminal focus reports reload external changes without per-buffer-entry :checktime.\n'
  for focus_scenario in unchanged external_change conflict buffer_switch; do
    printf "[behavior] Focus scenario: %s\n" "$focus_scenario"
    DOTFILES_FOCUS_SCENARIO="$focus_scenario" \
      run_nvim "checktime-focus-$focus_scenario" "$NVIM_FOCUS_TIMEOUT" \
        "+luafile $REPO_ROOT/tests/nvim/checktime-focus.lua"
  done

  printf '\n[behavior] Verifying a single scroll animation owner and native mouse wheel scrolling.\n'
  run_nvim "scrolling" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/scrolling.lua"

  printf '\n[behavior] Installing current Treesitter parsers and verifying real editor integrations.\n'
  run_nvim "treesitter-current-api" "$NVIM_TREESITTER_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/treesitter-current-api.lua" \
    "+qa!"

  printf '\n[behavior] Verifying Treesitter provisioning does not refresh cached parsers.\n'
  run_nvim "treesitter-provisioning" "$NVIM_TREESITTER_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/treesitter-provisioning.lua" \
    "+qa!"

  printf '\n[behavior] Verifying current-API Go textobjects and function navigation.\n'
  run_nvim "treesitter-go-textobjects" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/treesitter-go-textobjects.lua" \
    "+qa!"

  printf '\n[behavior] Verifying Lazy update preflight handles generated help-tag collisions.\n'
  run_nvim "lazy-update-preflight" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/lazy-update-preflight.lua" \
    "+qa!"

  printf '\n[behavior] Verifying native LSP configuration and single ownership.\n'
  run_nvim "lsp-native-setup" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/lsp-native-setup.lua" \
    "+qa!"

  printf '\n[behavior] Verifying lazydev loads only for Lua buffers.\n'
  run_nvim "lazydev-lazy-loading" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/lazydev-lazy-loading.lua" \
    "+qa!"

  printf '\n[behavior] Verifying real LuaLS completion for Neovim and plugin APIs.\n'
  run_nvim "lazydev-luals-completion" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/lazydev-luals-completion.lua" \
    "+qa!"

  printf '\n[behavior] Verifying Neotest and its adapters load only after a test action.\n'
  run_nvim "neotest-lazy-loading" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/neotest-lazy-loading.lua" \
    "+qa!"

  printf '\n[behavior] Verifying LuaSnip sessions survive idle CursorHold and end on region exit.\n'
  run_nvim "luasnip-idle-lifetime" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/luasnip-idle-lifetime.lua"

  printf '\n[behavior] Verifying Telescope and extensions load only on the first picker action.\n'
  run_nvim "telescope-lazy-loading" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/telescope-lazy-loading.lua" \
    "+qa!"

  printf '\n[behavior] Verifying the :Telescope command is a working first-use trigger.\n'
  run_nvim "telescope-command-trigger" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/telescope-command-trigger.lua" \
    "+qa!"

  printf '\n[behavior] Verifying project.nvim can lazy-load Telescope through its module trigger.\n'
  run_nvim "telescope-project-module-trigger" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/telescope-project-module-trigger.lua" \
    "+qa!"

  printf '\n[behavior] Verifying Go tooling loads only for Go-related filetypes.\n'
  run_nvim "go-lazy-loading-go" "$NVIM_STARTUP_TIMEOUT" \
    "+lua assert(package.loaded['go'] == nil, 'go.nvim loaded during an unrelated startup'); vim.cmd('setfiletype text'); assert(vim.bo.filetype == 'text', 'non-Go test buffer was not set to text'); vim.api.nvim_exec_autocmds('CmdlineEnter', { modeline = false }); assert(package.loaded['go'] == nil, 'go.nvim loaded on CmdlineEnter in a non-Go buffer'); print('PASS: CmdlineEnter in a text buffer leaves go.nvim unloaded'); vim.cmd('enew'); vim.cmd('setfiletype go'); assert(package.loaded['go'] ~= nil, 'go.nvim did not load for the Go filetype'); assert(vim.fn.exists(':GoBuild') == 2, 'GoBuild command is missing after Go plugin load'); print('PASS: Go filetype loads go.nvim and registers :GoBuild')" \
    "+qa!"

  run_nvim "go-lazy-loading-gomod" "$NVIM_STARTUP_TIMEOUT" \
    "+lua assert(package.loaded['go'] == nil, 'go.nvim loaded before the go.mod filetype'); vim.cmd('setfiletype gomod'); assert(vim.bo.filetype == 'gomod', 'go.mod test buffer was not set to gomod'); assert(package.loaded['go'] ~= nil, 'go.nvim did not load for the go.mod filetype'); assert(vim.fn.exists(':GoBuild') == 2, 'GoBuild command is missing for go.mod buffers'); print('PASS: gomod filetype loads go.nvim and registers :GoBuild')" \
    "+qa!"
  # Exercise Mason's first-use command with a clean registry before any
  # other DAP scenario downloads or installs adapters.
  run_nvim "dap-mason-command-trigger" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/dap-mason-command-trigger.lua" \
    "+qa!"

  run_nvim "dap-lazy-loading" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/dap-lazy-loading.lua" \
    "+qa!"

  run_nvim "dap-command-trigger" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/dap-command-trigger.lua" \
    "+qa!"

  run_nvim "dap-neotest-trigger" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/dap-neotest-trigger.lua" \
    "+qa!"

  printf '\n[behavior] Comparing syntax and manual folding around JavaScript O.\n'
  run_nvim "foldmethod-indent-diagnostic" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/foldmethod-indent-diagnostic.lua"

  printf '\n[behavior] Verifying scope-aware indentation for S, o and O.\n'
  # The scenario drives Neovim's main loop and exits itself. Do not append
  # +qa!: the deferred input assertions would never run.
  run_nvim "indented-substitute" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/indented-substitute.lua"

  printf '\n[behavior] Provisioning the optional Python provider and exercising failure preservation.\n'
  run_nvim "python-provider-provisioning" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/python-provider-provisioning.lua" \
    "+qa!"

  printf '\n[behavior] Verifying the Python provider in a fresh Neovim process.\n'
  run_nvim "python-provider-host" "$NVIM_STARTUP_TIMEOUT" \
    "+luafile $REPO_ROOT/tests/nvim/python-provider-host.lua" \
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
