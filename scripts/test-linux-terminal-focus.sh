#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$REPO_ROOT/scripts/test-linux-terminal-focus.sh"
NVIM_BIN="${NVIM_BIN:-nvim}"
NVIM_TEST_DIR="${NVIM_TEST_DIR:-}"

if [[ "$(uname -s)" != "Linux" ]]; then
  printf 'This integration test requires Linux, Xvfb, Openbox, and xterm.\n' >&2
  exit 2
fi
if [[ -z "$NVIM_TEST_DIR" || ! -d "$NVIM_TEST_DIR" ]]; then
  printf 'NVIM_TEST_DIR must point to the prepared isolated Neovim workspace.\n' >&2
  exit 2
fi

for required_command in "$NVIM_BIN" python3 xvfb-run openbox xterm wmctrl xprop; do
  command -v "$required_command" >/dev/null 2>&1 || {
    printf 'Required Linux terminal-focus command is missing: %s\n' "$required_command" >&2
    exit 1
  }
done

if [[ "${DOTFILES_XVFB_ACTIVE:-0}" != "1" ]]; then
  exec xvfb-run -a -s '-screen 0 1280x800x24 -nolisten tcp' \
    env DOTFILES_XVFB_ACTIVE=1 bash "$SCRIPT_PATH"
fi

NVIM_CONFIG="$NVIM_TEST_DIR/config/nvim/init.lua"
[[ -f "$NVIM_CONFIG" ]] || {
  printf 'Prepared Neovim config is missing: %s\n' "$NVIM_CONFIG" >&2
  exit 1
}

TEST_ROOT="$(mktemp -d "$NVIM_TEST_DIR/linux-terminal-focus.XXXXXX")"
RAW_READY="$TEST_ROOT/raw.ready"
RAW_RELEASE="$TEST_ROOT/raw.release"
RAW_DONE="$TEST_ROOT/raw.done"
RAW_LOST="$TEST_ROOT/raw-focus-lost.count"
RAW_GAINED="$TEST_ROOT/raw-focus-gained.count"
RAW_LOG="$TEST_ROOT/raw-probe.log"
TTY_FILE="$TEST_ROOT/terminal.tty"
LAUNCHER_LOG="$TEST_ROOT/launcher.log"
NVIM_READY="$TEST_ROOT/neovim.ready"
NVIM_LOST="$TEST_ROOT/neovim-focus-lost.count"
NVIM_GAINED="$TEST_ROOT/neovim-focus-gained.count"
VERBOSE_LOG="$TEST_ROOT/neovim-verbose.log"
STARTUP_LOG="$TEST_ROOT/neovim-startuptime.log"
NVIM_STDERR_LOG="$TEST_ROOT/neovim-stderr.log"
NVIM_EXIT_LOG="$TEST_ROOT/neovim-exit.log"
WM_LOG="$TEST_ROOT/openbox.log"
XTERM_TARGET_LOG="$TEST_ROOT/xterm-target.log"
XTERM_TARGET_SESSION_LOG="$TEST_ROOT/xterm-target-session.log"
XTERM_AWAY_LOG="$TEST_ROOT/xterm-away.log"

TARGET_TITLE="dotfiles-focus-target-$$"
AWAY_TITLE="dotfiles-focus-away-$$"
TARGET_PID=""
AWAY_PID=""
WM_PID=""
TARGET_WINDOW=""
AWAY_WINDOW=""

print_diagnostics() {
  printf '\n[linux-focus] Diagnostics from %s\n' "$TEST_ROOT" >&2
  for log in "$LAUNCHER_LOG" "$RAW_LOG" "$NVIM_STDERR_LOG" "$NVIM_EXIT_LOG" "$STARTUP_LOG" "$VERBOSE_LOG" "$XTERM_TARGET_SESSION_LOG" "$WM_LOG" "$XTERM_TARGET_LOG" "$XTERM_AWAY_LOG"; do
    if [[ -s "$log" ]]; then
      printf '\n--- %s ---\n' "${log##*/}" >&2
      tail -n 100 "$log" >&2 || true
    fi
  done
  if [[ -n "$TARGET_WINDOW" ]]; then
    wmctrl -l -p >&2 || true
    xprop -root _NET_ACTIVE_WINDOW >&2 || true
  fi
}

terminate_process_tree() {
  local parent="$1"
  local child
  while IFS= read -r child; do
    [[ "$child" =~ ^[0-9]+$ ]] || continue
    terminate_process_tree "$child"
  done < <(pgrep -P "$parent" || true)
  kill "$parent" 2>/dev/null || true
}

cleanup() {
  local status=$?
  : > "$RAW_RELEASE" 2>/dev/null || true
  for window in "$TARGET_WINDOW" "$AWAY_WINDOW"; do
    if [[ -n "$window" ]]; then
      wmctrl -ic "$window" >/dev/null 2>&1 || true
    fi
  done
  for pid in "$TARGET_PID" "$AWAY_PID" "$WM_PID"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      terminate_process_tree "$pid"
      wait "$pid" 2>/dev/null || true
    fi
  done
  if ((status != 0)); then
    print_diagnostics
  fi
  for pair in \
    "$LAUNCHER_LOG:linux-terminal-focus-launcher.log" \
    "$RAW_LOG:linux-terminal-focus-raw.log" \
    "$NVIM_STDERR_LOG:linux-terminal-focus-neovim-stderr.log" \
    "$NVIM_EXIT_LOG:linux-terminal-focus-neovim-exit.log" \
    "$STARTUP_LOG:linux-terminal-focus-startuptime.log" \
    "$VERBOSE_LOG:linux-terminal-focus-verbose.log" \
    "$XTERM_TARGET_SESSION_LOG:linux-terminal-focus-target-session.log" \
    "$WM_LOG:linux-terminal-focus-openbox.log" \
    "$XTERM_TARGET_LOG:linux-terminal-focus-target-xterm.log" \
    "$XTERM_AWAY_LOG:linux-terminal-focus-away-xterm.log"; do
    source="${pair%%:*}"
    destination="${pair#*:}"
    [[ ! -e "$source" ]] || cp "$source" "$NVIM_TEST_DIR/$destination"
  done
  if ((status == 0)); then
    rm -rf "$TEST_ROOT"
  else
    printf '[linux-focus] Failure artifacts preserved at %s\n' "$TEST_ROOT" >&2
  fi
  return "$status"
}
trap cleanup EXIT

export HOME="$NVIM_TEST_DIR/home"
export XDG_CONFIG_HOME="$NVIM_TEST_DIR/config"
export XDG_DATA_HOME="$NVIM_TEST_DIR/data"
export XDG_STATE_HOME="$NVIM_TEST_DIR/state"
export XDG_CACHE_HOME="$NVIM_TEST_DIR/cache"
export TERM=xterm-256color

mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
: > "$LAUNCHER_LOG"
printf '0\n' > "$NVIM_LOST"
printf '0\n' > "$NVIM_GAINED"

openbox --sm-disable >"$WM_LOG" 2>&1 &
WM_PID=$!
wm_ready=0
for _ in $(seq 1 100); do
  if wmctrl -m >/dev/null 2>&1; then
    wm_ready=1
    break
  fi
  sleep 0.1
done
((wm_ready == 1)) || {
  printf 'Openbox did not become ready under Xvfb.\n' >&2
  exit 1
}
printf '[linux-focus] Xvfb display=%s; Openbox is ready.\n' "$DISPLAY"

cat > "$TEST_ROOT/target-session.sh" <<'TARGET'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '[launcher] target shell pid=%s tty=%s\n' "$BASHPID" "$(tty)" >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"
printf '%s\n' "$(tty)" > "$DOTFILES_TERMINAL_FOCUS_TTY_FILE"
: > "$DOTFILES_TERMINAL_FOCUS_NVIM_STDERR_LOG"
printf '[launcher] Neovim stderr capture started\n' >> "$DOTFILES_TERMINAL_FOCUS_NVIM_STDERR_LOG"
: > "$DOTFILES_TERMINAL_FOCUS_NVIM_EXIT_LOG"
if python3 "$DOTFILES_TERMINAL_FOCUS_PROBE" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_READY" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_RELEASE" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_DONE" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_LOST" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_GAINED" \
  "$DOTFILES_TERMINAL_FOCUS_RAW_LOG" >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG" 2>&1; then
  probe_status=0
else
  probe_status=$?
fi
if [[ "$(cat "$DOTFILES_TERMINAL_FOCUS_RAW_DONE")" != "ok" ]]; then
  printf '[launcher] raw focus probe did not restore the TTY cleanly (exit=%s).\n' "$probe_status" >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"
  exit 1
fi

nvim_args=(
  --cmd 'set nomore shortmess+=I'
  --startuptime "$DOTFILES_TERMINAL_FOCUS_STARTUP_LOG"
  "-V12$DOTFILES_TERMINAL_FOCUS_VERBOSE_LOG"
  -u "$DOTFILES_TERMINAL_FOCUS_INIT"
  -c 'lua
    local lost = vim.env.DOTFILES_TERMINAL_FOCUS_NVIM_LOST
    local gained = vim.env.DOTFILES_TERMINAL_FOCUS_NVIM_GAINED
    local ready = vim.env.DOTFILES_TERMINAL_FOCUS_NVIM_READY
    assert(#vim.api.nvim_list_uis() > 0, "Neovim did not attach to the xterm TUI")
    local function increment(path)
      local lines = vim.fn.readfile(path)
      local count = tonumber(lines[1] or "0") or 0
      assert(vim.fn.writefile({ tostring(count + 1) }, path) == 0, "could not write focus counter: " .. path)
    end
    vim.api.nvim_create_autocmd("FocusLost", { callback = function() increment(lost); print("NATIVE FocusLost") end })
    vim.api.nvim_create_autocmd("FocusGained", { callback = function() increment(gained); print("NATIVE FocusGained") end })
    assert(vim.fn.writefile({ "1" }, ready) == 0, "could not publish Neovim readiness")
    print("UI ready on Linux xterm PTY")'
)

printf '[launcher] raw probe restored termios; launching Neovim child on the same TTY.\n' >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"
printf '[launcher] executable=%s executable_file=%s\n' \
  "$DOTFILES_TERMINAL_FOCUS_NVIM_BIN" \
  "$([[ -x "$DOTFILES_TERMINAL_FOCUS_NVIM_BIN" ]] && echo yes || echo no)" \
  >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"
{
  printf '[launcher] argv:'
  printf ' %q' "$DOTFILES_TERMINAL_FOCUS_NVIM_BIN" "${nvim_args[@]}"
  printf '\n'
} >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"

if [[ ! -x "$DOTFILES_TERMINAL_FOCUS_NVIM_BIN" ]]; then
  nvim_status=127
  printf '[launcher] ERROR: Neovim executable is missing or not executable.\n' \
    >> "$DOTFILES_TERMINAL_FOCUS_NVIM_STDERR_LOG"
elif "$DOTFILES_TERMINAL_FOCUS_NVIM_BIN" "${nvim_args[@]}" \
  2>> "$DOTFILES_TERMINAL_FOCUS_NVIM_STDERR_LOG"; then
  nvim_status=0
else
  nvim_status=$?
fi

printf 'exit_status=%s\n' "$nvim_status" > "$DOTFILES_TERMINAL_FOCUS_NVIM_EXIT_LOG"
printf '[launcher] Neovim child exited with status=%s.\n' "$nvim_status" \
  >> "$DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG"
exit "$nvim_status"
TARGET
chmod +x "$TEST_ROOT/target-session.sh"
if ! bash -n "$TEST_ROOT/target-session.sh"; then
  printf 'Generated target-session launcher has invalid Bash syntax.\n' >&2
  exit 1
fi
printf '[linux-focus] Generated target-session launcher passed bash -n.\n'

export DOTFILES_SKIP_MASON_LSP_INSTALL=1
export DOTFILES_SKIP_TREESITTER_PROVISIONING=1
export DOTFILES_TERMINAL_FOCUS_PROBE="$REPO_ROOT/scripts/run_terminal_focus_probe.py"
export DOTFILES_TERMINAL_FOCUS_LAUNCHER_LOG="$LAUNCHER_LOG"
export DOTFILES_TERMINAL_FOCUS_TTY_FILE="$TTY_FILE"
export DOTFILES_TERMINAL_FOCUS_RAW_READY="$RAW_READY"
export DOTFILES_TERMINAL_FOCUS_RAW_RELEASE="$RAW_RELEASE"
export DOTFILES_TERMINAL_FOCUS_RAW_DONE="$RAW_DONE"
export DOTFILES_TERMINAL_FOCUS_RAW_LOST="$RAW_LOST"
export DOTFILES_TERMINAL_FOCUS_RAW_GAINED="$RAW_GAINED"
export DOTFILES_TERMINAL_FOCUS_RAW_LOG="$RAW_LOG"
export DOTFILES_TERMINAL_FOCUS_NVIM_BIN="$(command -v "$NVIM_BIN")"
export DOTFILES_TERMINAL_FOCUS_NVIM_STDERR_LOG="$NVIM_STDERR_LOG"
export DOTFILES_TERMINAL_FOCUS_NVIM_EXIT_LOG="$NVIM_EXIT_LOG"
export DOTFILES_TERMINAL_FOCUS_INIT="$NVIM_CONFIG"
export DOTFILES_TERMINAL_FOCUS_NVIM_READY="$NVIM_READY"
export DOTFILES_TERMINAL_FOCUS_NVIM_LOST="$NVIM_LOST"
export DOTFILES_TERMINAL_FOCUS_NVIM_GAINED="$NVIM_GAINED"
export DOTFILES_TERMINAL_FOCUS_STARTUP_LOG="$STARTUP_LOG"
export DOTFILES_TERMINAL_FOCUS_VERBOSE_LOG="$VERBOSE_LOG"

printf '[linux-focus] Starting target xterm window and raw TTY observer.\n'
xterm -T "$TARGET_TITLE" -geometry 100x30+20+20 \
  -l -lf "$XTERM_TARGET_SESSION_LOG" \
  -e /bin/bash "$TEST_ROOT/target-session.sh" >"$XTERM_TARGET_LOG" 2>&1 &
TARGET_PID=$!

wait_for_window() {
  local title="$1"
  local deadline=$((SECONDS + 15))
  local found=""
  while ((SECONDS < deadline)); do
    found="$(wmctrl -l | awk -v title="$title" 'index($0, title) { print $1; exit }')"
    if [[ -n "$found" ]]; then
      printf '%s' "$found"
      return 0
    fi
    sleep 0.1
  done
  printf 'Could not find X11 window with title %s.\n' "$title" >&2
  return 1
}

TARGET_WINDOW="$(wait_for_window "$TARGET_TITLE")"
wait_for_file_value() {
  local path="$1"
  local expected="$2"
  local description="$3"
  local deadline=$((SECONDS + 30))
  while ((SECONDS < deadline)); do
    if [[ -s "$path" ]] && [[ "$(tr -d '\r\n' < "$path")" == "$expected" ]]; then
      printf '[linux-focus] %s\n' "$description"
      return 0
    fi
    if ! kill -0 "$TARGET_PID" 2>/dev/null; then
      printf 'Target xterm exited before %s.\n' "$description" >&2
      return 1
    fi
    sleep 0.1
  done
  printf 'Timed out waiting for %s (%s).\n' "$description" "$path" >&2
  return 1
}
wait_for_file_value "$RAW_READY" "1" "raw TTY observer enabled DECSET 1004"

printf '[linux-focus] Starting the second xterm window to cause genuine X11 focus changes.\n'
xterm -T "$AWAY_TITLE" -geometry 100x30+650+20 -e /bin/bash -c 'exec sleep 300' \
  >"$XTERM_AWAY_LOG" 2>&1 &
AWAY_PID=$!
AWAY_WINDOW="$(wait_for_window "$AWAY_TITLE")"

read_counter() {
  local path="$1"
  if [[ -s "$path" ]]; then
    tr -d '\r\n' < "$path"
  else
    printf '0'
  fi
}

activate_window() {
  local window="$1"
  local deadline=$((SECONDS + 5))
  local active=""
  wmctrl -i -a "$window"
  while ((SECONDS < deadline)); do
    active="$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | sed -E 's/.*# (0x[0-9a-fA-F]+).*/\1/' || true)"
    if [[ "$active" =~ ^0x[0-9a-fA-F]+$ ]] && ((active == window)); then
      return 0
    fi
    sleep 0.1
  done
  printf 'Window manager did not activate %s (active=%s).\n' "$window" "$active" >&2
  return 1
}

wait_for_counter_gt() {
  local path="$1"
  local previous="$2"
  local description="$3"
  local deadline=$((SECONDS + 10))
  local current=""
  while ((SECONDS < deadline)); do
    current="$(read_counter "$path")"
    if [[ "$current" =~ ^[0-9]+$ ]] && ((current > previous)); then
      printf 'PASS: %s (%s -> %s)\n' "$description" "$previous" "$current"
      return 0
    fi
    sleep 0.1
  done
  printf 'FAIL: %s; expected counter > %s, got %s.\n' "$description" "$previous" "${current:-missing}" >&2
  return 1
}

activate_window "$TARGET_WINDOW"
raw_lost_before="$(read_counter "$RAW_LOST")"
raw_gained_before="$(read_counter "$RAW_GAINED")"
activate_window "$AWAY_WINDOW"
wait_for_counter_gt "$RAW_LOST" "$raw_lost_before" \
  'xterm emitted native FocusLost bytes to the real /dev/pts TTY'
activate_window "$TARGET_WINDOW"
wait_for_counter_gt "$RAW_GAINED" "$raw_gained_before" \
  'xterm emitted native FocusGained bytes to the same real TTY'
: > "$RAW_RELEASE"
wait_for_file_value "$RAW_DONE" "ok" "raw observer restored termios and disabled DECSET 1004"

if [[ ! -s "$TTY_FILE" ]]; then
  printf 'Target launcher did not record its terminal device.\n' >&2
  exit 1
fi
tty_path="$(tr -d '\r\n' < "$TTY_FILE")"
[[ "$tty_path" == /dev/pts/* ]] || {
  printf 'Expected a real Linux PTY under /dev/pts, got %s.\n' "$tty_path" >&2
  exit 1
}
printf '[linux-focus] Neovim will launch on the same PTY: %s\n' "$tty_path"
wait_for_file_value "$NVIM_READY" "1" "Neovim TUI registered native focus callbacks and became ready"

lost_before="$(read_counter "$NVIM_LOST")"
activate_window "$AWAY_WINDOW"
wait_for_counter_gt "$NVIM_LOST" "$lost_before" \
  'Neovim received its native FocusLost callback through xterm and the real PTY'

gained_before="$(read_counter "$NVIM_GAINED")"
activate_window "$TARGET_WINDOW"
wait_for_counter_gt "$NVIM_GAINED" "$gained_before" \
  'Neovim received its native FocusGained callback through xterm and the real PTY'

lost_before="$(read_counter "$NVIM_LOST")"
activate_window "$AWAY_WINDOW"
wait_for_counter_gt "$NVIM_LOST" "$lost_before" \
  'second X11 focus loss reached Neovim as a native FocusLost callback'

gained_before="$(read_counter "$NVIM_GAINED")"
activate_window "$TARGET_WINDOW"
wait_for_counter_gt "$NVIM_GAINED" "$gained_before" \
  'second X11 focus return reached Neovim as a native FocusGained callback'

printf '[linux-focus] Raw TTY counts: FocusLost=%s FocusGained=%s\n' \
  "$(read_counter "$RAW_LOST")" "$(read_counter "$RAW_GAINED")"
printf '[linux-focus] Neovim callback counts: FocusLost=%s FocusGained=%s\n' \
  "$(read_counter "$NVIM_LOST")" "$(read_counter "$NVIM_GAINED")"
printf 'PASS: Linux xterm -> away window -> xterm native focus transitions reached Neovim through the real TUI PTY.\n'
