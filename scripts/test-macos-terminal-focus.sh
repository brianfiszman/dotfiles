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
for required_command in open osascript tty; do
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
socket_path="/tmp/nvim-terminal-focus-$(id -u)-$$.sock"
command_file="$test_root/start-neovim.command"
pid_file="$test_root/neovim.pid"
tty_file="$test_root/terminal.tty"

cleanup() {
  if [[ -S "$socket_path" ]]; then
    "$NVIM_BIN" --server "$socket_path" --remote-send ':qa!<CR>' >/dev/null 2>&1 || true
  fi
  if [[ -s "$pid_file" ]]; then
    child_pid="$(cat "$pid_file")"
    if [[ "$child_pid" =~ ^[0-9]+$ ]] && kill -0 "$child_pid" 2>/dev/null; then
      kill "$child_pid" 2>/dev/null || true
    fi
  fi
  rm -f "$socket_path"
  rm -rf "$test_root"
}
trap cleanup EXIT

socket_length="$(printf '%s' "$socket_path" | wc -c | tr -d ' ')"
if ((socket_length >= 100)); then
  printf 'The temporary Neovim RPC socket path is too long for macOS: %s\n' "$socket_path" >&2
  exit 1
fi

printf -v q_home '%q' "$NVIM_TEST_DIR/home"
printf -v q_config '%q' "$NVIM_TEST_DIR/config"
printf -v q_data '%q' "$NVIM_TEST_DIR/data"
printf -v q_state '%q' "$NVIM_TEST_DIR/state"
printf -v q_cache '%q' "$NVIM_TEST_DIR/cache"
printf -v q_nvim '%q' "$NVIM_BIN"
printf -v q_socket '%q' "$socket_path"
printf -v q_pid '%q' "$pid_file"
printf -v q_tty '%q' "$tty_file"
printf -v q_init '%q' "$NVIM_TEST_DIR/config/nvim/init.lua"

# Opening a .command file in Terminal.app starts Neovim on the app's actual
# terminal PTY. The return transition selects the exact session window through
# Terminal's scripting dictionary; it does not synthesize terminal focus bytes
# or use System Events UI/Accessibility scripting.
cat > "$command_file" <<EOF
#!/bin/bash
set -Eeuo pipefail
export HOME=$q_home
export XDG_CONFIG_HOME=$q_config
export XDG_DATA_HOME=$q_data
export XDG_STATE_HOME=$q_state
export XDG_CACHE_HOME=$q_cache
export TERM=xterm-256color
echo \$\$ > $q_pid
tty > $q_tty
exec $q_nvim --listen $q_socket --cmd 'set nomore' -u $q_init \\
  -c 'lua vim.g.dotfiles_macos_focus_lost = 0; vim.g.dotfiles_macos_focus_gained = 0; vim.api.nvim_create_autocmd("FocusLost", { callback = function() vim.g.dotfiles_macos_focus_lost = vim.g.dotfiles_macos_focus_lost + 1 end }); vim.api.nvim_create_autocmd("FocusGained", { callback = function() vim.g.dotfiles_macos_focus_gained = vim.g.dotfiles_macos_focus_gained + 1 end }); vim.g.dotfiles_macos_focus_ready = 1'
EOF
chmod 700 "$command_file"

remote_expr() {
  "$NVIM_BIN" --server "$socket_path" --remote-expr "$1" 2>/dev/null | tr -d '\r\n'
}

read_counter() {
  remote_expr "get(g:, '$1', 0)"
}

wait_for_ready() {
  for _ in {1..150}; do
    if [[ -S "$socket_path" ]]; then
      ready="$(remote_expr "get(g:, 'dotfiles_macos_focus_ready', 0)" || true)"
      if [[ "$ready" == "1" ]]; then
        return 0
      fi
    fi
    sleep 0.2
  done
  printf 'Terminal.app did not start Neovim with a responsive RPC server. Inspect %s\n' "$command_file" >&2
  return 1
}

wait_for_counter_gt() {
  name="$1"
  previous="$2"
  description="$3"
  current=""
  for _ in {1..100}; do
    current="$(read_counter "$name" || true)"
    if [[ "$current" =~ ^[0-9]+$ ]] && ((current > previous)); then
      printf 'PASS: %s (%s -> %s)\n' "$description" "$previous" "$current"
      return 0
    fi
    sleep 0.1
  done
  printf 'FAIL: %s; expected %s to increase beyond %s, got %s\n' \
    "$description" "$name" "$previous" "${current-unavailable}" >&2
  return 1
}


wait_for_terminal_tty() {
  for _ in {1..100}; do
    if [[ -s "$tty_file" ]]; then
      return 0
    fi
    sleep 0.1
  done
  printf 'Terminal.app did not publish the Neovim session TTY at %s\n' "$tty_file" >&2
  return 1
}

activate_neovim_terminal_window() {
  wait_for_terminal_tty
  local target_tty
  target_tty="$(tr -d '\r\n' < "$tty_file")"
  [[ "$target_tty" == /dev/ttys* ]] || {
    printf 'Unexpected Neovim Terminal.app TTY: %s\n' "$target_tty" >&2
    return 1
  }

  printf '[macos-focus] Selecting the Terminal.app window attached to %s.\n' "$target_tty"
  osascript - "$target_tty" <<'APPLESCRIPT'
on run argv
  set targetTTY to item 1 of argv
  with timeout of 10 seconds
    tell application "Terminal"
      set matchingWindow to missing value
      repeat with candidateWindow in every window
        repeat with candidateTab in every tab of candidateWindow
          if (tty of candidateTab as text) is targetTTY then
            set matchingWindow to contents of candidateWindow
            set selected tab of candidateWindow to candidateTab
            exit repeat
          end if
        end repeat
        if matchingWindow is not missing value then exit repeat
      end repeat

      if matchingWindow is missing value then
        error "No Terminal.app window owns Neovim TTY " & targetTTY
      end if

      set index of matchingWindow to 1
      activate
      if (index of matchingWindow) is not 1 then
        error "The Neovim Terminal.app window did not become the front window"
      end if
      return tty of selected tab of matchingWindow
    end tell
  end timeout
end run
APPLESCRIPT
}printf '[macos-focus] Starting Neovim inside the real Terminal.app window.\n'
open -a Terminal "$command_file"
wait_for_ready

lost_before="$(read_counter dotfiles_macos_focus_lost)"
gained_before="$(read_counter dotfiles_macos_focus_gained)"
[[ "$lost_before" =~ ^[0-9]+$ && "$gained_before" =~ ^[0-9]+$ ]] || {
  printf 'Neovim focus counters were not readable over RPC (lost=%s gained=%s).\n' \
    "$lost_before" "$gained_before" >&2
  exit 1
}

printf '[macos-focus] Activating Finder to force Terminal.app to lose key-window focus.\n'
open -a Finder
wait_for_counter_gt dotfiles_macos_focus_lost "$lost_before" \
  'Finder activation generated a real Terminal.app FocusLost event'

gained_after="$(read_counter dotfiles_macos_focus_gained)"

printf '[macos-focus] Reactivating the exact Neovim Terminal.app window.\n'
activate_neovim_terminal_window
wait_for_counter_gt dotfiles_macos_focus_gained "$gained_after" \
  'Terminal.app reactivation generated a real Neovim FocusGained event'
lost_final="$(read_counter dotfiles_macos_focus_lost)"
gained_final="$(read_counter dotfiles_macos_focus_gained)"
printf '[macos-focus] Final native event counts: FocusLost=%s FocusGained=%s\n' \
  "$lost_final" "$gained_final"
printf 'PASS: macOS Terminal.app -> Finder -> Terminal.app focus transition reached Neovim through the real TUI PTY.\n'
