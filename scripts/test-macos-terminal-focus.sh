#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NVIM_BIN="${NVIM_BIN-nvim}"
NVIM_TEST_DIR="${NVIM_TEST_DIR-}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This integration test requires macOS and Terminal.app.\n' >&2
  exit 2
fi
if [[ -z "$NVIM_TEST_DIR" ]]; then
  printf 'NVIM_TEST_DIR must point at the prepared macOS Neovim workspace.\n' >&2
  exit 2
fi

NVIM_BIN="$(command -v "$NVIM_BIN")"
for required_command in open osascript python3 swift tty ps; do
  command -v "$required_command" >/dev/null 2>&1 || {
    printf 'Required macOS GUI test command is missing: %s\n' "$required_command" >&2
    exit 1
  }
done

for required_path in \
  "$NVIM_TEST_DIR/home" \
  "$NVIM_TEST_DIR/config/nvim/init.lua" \
  "$NVIM_TEST_DIR/data/nvim/lazy"; do
  [[ -e "$required_path" ]] || {
    printf 'Prepared Neovim workspace is incomplete: %s\n' "$required_path" >&2
    exit 1
  }
done

test_root="${RUNNER_TEMP-${TMPDIR-/tmp}}/nvim-terminal-focus-${GITHUB_RUN_ID-local}-$$"
mkdir -p "$test_root"
command_file="$test_root/start-neovim.command"
pid_file="$test_root/neovim.pid"
tty_file="$test_root/terminal.tty"
ready_file="$test_root/neovim.ready"
focus_lost_file="$test_root/focus-lost.count"
focus_gained_file="$test_root/focus-gained.count"
launcher_log="$test_root/launcher.log"
startup_verbose_log="$test_root/neovim-verbose.log"
startup_timing_log="$test_root/neovim-startuptime.log"

cleanup() {
  if [[ -s "$pid_file" ]]; then
    child_pid="$(cat "$pid_file")"
    if [[ "$child_pid" =~ ^[0-9]+$ ]] && kill -0 "$child_pid" 2>/dev/null; then
      kill "$child_pid" 2>/dev/null || true
    fi
  fi
  rm -rf "$test_root"
}
trap cleanup EXIT

printf -v q_home '%q' "$NVIM_TEST_DIR/home"
printf -v q_config '%q' "$NVIM_TEST_DIR/config"
printf -v q_data '%q' "$NVIM_TEST_DIR/data"
printf -v q_state '%q' "$NVIM_TEST_DIR/state"
printf -v q_cache '%q' "$NVIM_TEST_DIR/cache"
printf -v q_nvim '%q' "$NVIM_BIN"
printf -v q_pid '%q' "$pid_file"
printf -v q_tty '%q' "$tty_file"
printf -v q_init '%q' "$NVIM_TEST_DIR/config/nvim/init.lua"
printf -v q_ready_file '%q' "$ready_file"
printf -v q_focus_lost_file '%q' "$focus_lost_file"
printf -v q_focus_gained_file '%q' "$focus_gained_file"
printf -v q_launcher_log '%q' "$launcher_log"
printf -v q_verbose_log '%q' "$startup_verbose_log"
printf -v q_timing_log '%q' "$startup_timing_log"

# Launch Neovim on Terminal.app's actual terminal PTY. Launch Services opens
# the .command file first; Terminal's AppleScript do-script command is a
# fallback for runners where opening the document does not execute it.
# The Finder/Terminal focus transition remains native and never synthesizes
# terminal focus bytes or uses System Events UI/Accessibility scripting.
cat > "$command_file" <<EOF
#!/bin/bash
set -Eeuo pipefail
export HOME=$q_home
export XDG_CONFIG_HOME=$q_config
export XDG_DATA_HOME=$q_data
export XDG_STATE_HOME=$q_state
export XDG_CACHE_HOME=$q_cache
export TERM=xterm-256color
# This test validates native Terminal.app focus events only. The independent
# startup/LSP integration path covers Mason package installation.
export DOTFILES_SKIP_MASON_LSP_INSTALL=1
export DOTFILES_SKIP_TREESITTER_PROVISIONING=1
export DOTFILES_FOCUS_READY_FILE=$q_ready_file
export DOTFILES_FOCUS_LOST_FILE=$q_focus_lost_file
export DOTFILES_FOCUS_GAINED_FILE=$q_focus_gained_file
echo \$\$ > $q_pid
{
  printf '[launcher] shell started; pid=%s\n' "\$\$"
  printf '[launcher] Neovim executable: %s\n' $q_nvim
  printf '[launcher] config: %s\n' $q_init
} >> $q_launcher_log
tty > $q_tty 2>> $q_launcher_log
exec $q_nvim --cmd 'set nomore shortmess+=I' \
  --cmd 'lua local function write_count(key, path) local count = (vim.g[key] or 0) + 1; vim.g[key] = count; assert(vim.fn.writefile({tostring(count)}, path) == 0) end; vim.g.dotfiles_macos_focus_lost = 0; vim.g.dotfiles_macos_focus_gained = 0; vim.api.nvim_create_autocmd("FocusLost", { callback = function() write_count("dotfiles_macos_focus_lost", vim.env.DOTFILES_FOCUS_LOST_FILE) end }); vim.api.nvim_create_autocmd("FocusGained", { callback = function() write_count("dotfiles_macos_focus_gained", vim.env.DOTFILES_FOCUS_GAINED_FILE) end }); vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = function() assert(vim.fn.writefile({"1"}, vim.env.DOTFILES_FOCUS_READY_FILE) == 0) end })' \
  --startuptime $q_timing_log -V12$q_verbose_log -u $q_init 2>> $q_launcher_log
EOF
chmod 700 "$command_file"

read_counter() {
  local file=""
  case "$1" in
    dotfiles_macos_focus_lost) file="$focus_lost_file" ;;
    dotfiles_macos_focus_gained) file="$focus_gained_file" ;;
    *) printf 'Unknown focus counter: %s\\n' "$1" >&2; return 2 ;;
  esac
  if [[ -s "$file" ]]; then
    tr -d '\\r\\n' < "$file"
  else
    printf '0'
  fi
}
wait_for_launcher() {
  local deadline=$((SECONDS + 5))
  local child_pid=""
  while ((SECONDS < deadline)); do
    if [[ -s "$pid_file" ]]; then
      child_pid="$(cat "$pid_file")"
      if [[ "$child_pid" =~ ^[0-9]+$ ]] && kill -0 "$child_pid" 2>/dev/null; then
        return 0
      fi
    fi
    sleep 0.1
  done
  return 1
}

launch_through_terminal_scripting() {
  printf '[macos-focus] Launch Services opened Terminal.app but did not execute the .command; trying Terminal scripting.\n'
  python3 - "$command_file" <<'PY'
import subprocess
import sys

script = """on run argv
  set commandPath to item 1 of argv
  tell application "Terminal"
    activate
    do script "bash " & quoted form of commandPath
  end tell
end run
"""

try:
    result = subprocess.run(
        ["osascript", "-", sys.argv[1]],
        input=script,
        text=True,
        check=False,
        timeout=15,
        capture_output=True,
    )
except subprocess.TimeoutExpired:
    print("[macos-focus] Terminal AppleScript fallback exceeded its 15-second deadline", file=sys.stderr)
    raise SystemExit(124)

if result.stdout:
    print(result.stdout, end="")
if result.returncode != 0:
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    raise SystemExit(result.returncode)
PY
}

print_startup_diagnostics() {
  printf '[macos-focus] Launcher diagnostics follow.\n'
  if [[ -s "$launcher_log" ]]; then
    cat "$launcher_log"
  else
    printf '[macos-focus] The generated .command never reached its launcher marker.\n'
  fi
  if [[ -s "$pid_file" ]]; then
    local child_pid
    child_pid="$(cat "$pid_file")"
    printf '[macos-focus] Neovim pid file: %s\n' "$child_pid"
    if [[ "$child_pid" =~ ^[0-9]+$ ]]; then
      ps -o pid=,ppid=,stat=,command= -p "$child_pid" || true
    fi
  fi
  if [[ -s "$tty_file" ]]; then
    printf '[macos-focus] Neovim TTY: %s\n' "$(tr -d '\r\n' < "$tty_file")"
  fi
  if [[ -s "$startup_verbose_log" ]]; then
    printf '[macos-focus] Neovim verbose startup tail:\n'
    tail -n 40 "$startup_verbose_log"
  fi
  if [[ -s "$startup_timing_log" ]]; then
    printf '[macos-focus] Neovim startup timing tail:\n'
    tail -n 20 "$startup_timing_log"
  fi
}

wait_for_ready() {
  local deadline=$((SECONDS + 30))
  while ((SECONDS < deadline)); do
    if [[ -s "$ready_file" ]] && [[ "$(tr -d '\\r\\n' < "$ready_file")" == "1" ]]; then
      printf '[macos-focus] Neovim attached its real TTY UI and published the UIEnter ready marker.\\n'
      return 0
    fi
    sleep 0.2
  done
  printf 'Terminal.app did not complete Neovim startup within 30 seconds.\\n' >&2
  print_startup_diagnostics >&2
  return 1
}
wait_for_counter_gt() {
  local name="$1"
  local previous="$2"
  local description="$3"
  local current=""
  local deadline=$((SECONDS + 10))

  while ((SECONDS < deadline)); do
    current="$(read_counter "$name" || true)"
    if [[ "$current" =~ ^[0-9]+$ ]] && ((current > previous)); then
      printf 'PASS: %s (%s -> %s)\n' "$description" "$previous" "$current"
      return 0
    fi
    sleep 0.1
  done
  printf 'FAIL: %s; expected %s to increase beyond %s within 10 seconds, got %s\n' \
    "$description" "$name" "$previous" "${current-unavailable}" >&2
  return 1
}


request_appkit_activation() {
  local bundle_id="$1"
  local app_name="$2"
  local swift_script="$test_root/activate-app.swift"

  printf '[macos-focus] Requesting native %s activation through AppKit.\n' "$app_name"
  cat > "$swift_script" <<'SWIFT'
import AppKit
import Foundation

let bundleID = CommandLine.arguments[1]
let appName = CommandLine.arguments[2]
guard let application = NSRunningApplication.runningApplications(
  withBundleIdentifier: bundleID
).first else {
  fputs("Cannot activate \(appName): application is not running.\n", stderr)
  exit(1)
}

let activated = application.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
guard activated else {
  fputs("AppKit refused to activate \(appName).\n", stderr)
  exit(1)
}

print("AppKit activated \(appName); isActive=\(application.isActive)")
SWIFT

  python3 - "$swift_script" "$bundle_id" "$app_name" <<'PY'
import subprocess
import sys

try:
    result = subprocess.run(
        ["swift", sys.argv[1], sys.argv[2], sys.argv[3]],
        check=False,
        timeout=30,
    )
except subprocess.TimeoutExpired:
    print(f"AppKit activation helper for {sys.argv[3]} exceeded its 30-second deadline", file=sys.stderr)
    raise SystemExit(124)

raise SystemExit(result.returncode)
PY
}
wait_for_counter_increase() {
  local name="$1"
  local previous="$2"
  local attempts="$3"
  local description="$4"
  local quiet="${5:-false}"
  local current=""
  local deadline=$((SECONDS + (attempts + 9) / 10))

  while ((SECONDS < deadline)); do
    current="$(read_counter "$name" || true)"
    if [[ "$current" =~ ^[0-9]+$ ]] && ((current > previous)); then
      if [[ "$quiet" != "true" ]]; then
        printf 'PASS: %s (%s -> %s)\n' "$description" "$previous" "$current"
      fi
      return 0
    fi
    sleep 0.1
  done

  if [[ "$quiet" != "true" ]]; then
    printf 'FAIL: %s; expected %s to increase beyond %s, got %s\n' \
      "$description" "$name" "$previous" "${current-unavailable}" >&2
  fi
  return 1
}

printf '[macos-focus] Starting Neovim inside the real Terminal.app window.\n'
open -a Terminal "$command_file"
if ! wait_for_launcher; then
  launch_through_terminal_scripting
  wait_for_launcher || {
    printf '[macos-focus] Terminal.app did not execute the generated launcher after either launch path.\n' >&2
    print_startup_diagnostics >&2
    exit 1
  }
fi
wait_for_ready

lost_before="$(read_counter dotfiles_macos_focus_lost)"
gained_before="$(read_counter dotfiles_macos_focus_gained)"
[[ "$lost_before" =~ ^[0-9]+$ && "$gained_before" =~ ^[0-9]+$ ]] || {
  printf 'Neovim focus counters were not initialized by their autocmds (lost=%s gained=%s).\n' \
    "$lost_before" "$gained_before" >&2
  exit 1
}

printf '[macos-focus] Activating Finder to force Terminal.app to lose key-window focus.\n'
open -a Finder
request_appkit_activation "com.apple.finder" "Finder"
wait_for_counter_gt dotfiles_macos_focus_lost "$lost_before" \
  'Finder activation generated a real Terminal.app FocusLost event'
gained_after="$(read_counter dotfiles_macos_focus_gained)"

printf '[macos-focus] Reactivating Terminal.app through Launch Services.\n'
open -a Terminal
if ! wait_for_counter_increase dotfiles_macos_focus_gained "$gained_after" 25 \
  'Terminal.app reactivation generated a real Neovim FocusGained event' true; then
  printf '[macos-focus] Launch Services did not restore the Neovim TTY; using AppKit activation fallback.\n'
  request_appkit_activation "com.apple.Terminal" "Terminal.app"
  wait_for_counter_increase dotfiles_macos_focus_gained "$gained_after" 100 \
    'AppKit activation generated a real Neovim FocusGained event'
fi
lost_final="$(read_counter dotfiles_macos_focus_lost)"
gained_final="$(read_counter dotfiles_macos_focus_gained)"
printf '[macos-focus] Final native event counts: FocusLost=%s FocusGained=%s\n' \
  "$lost_final" "$gained_final"
printf 'PASS: macOS Terminal.app -> Finder -> Terminal.app focus transition reached Neovim through the real TUI PTY.\n'
