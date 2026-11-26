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
terminal_window_focus_script="$test_root/terminal-window-focus.swift"
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
  --startuptime $q_timing_log -V12$q_verbose_log -u $q_init \
  -c 'lua local function write_count(key, path) local count = (vim.g[key] or 0) + 1; vim.g[key] = count; assert(vim.fn.writefile({tostring(count)}, path) == 0); print("[macos-focus] Neovim received " .. key .. " (" .. count .. ")") end; vim.g.dotfiles_macos_focus_lost = 0; vim.g.dotfiles_macos_focus_gained = 0; vim.api.nvim_create_autocmd("FocusLost", { callback = function() write_count("dotfiles_macos_focus_lost", vim.env.DOTFILES_FOCUS_LOST_FILE) end }); vim.api.nvim_create_autocmd("FocusGained", { callback = function() write_count("dotfiles_macos_focus_gained", vim.env.DOTFILES_FOCUS_GAINED_FILE) end }); vim.api.nvim_create_autocmd("UIEnter", { once = true, callback = function() assert(vim.fn.writefile({"1"}, vim.env.DOTFILES_FOCUS_READY_FILE) == 0) end })' 2>> $q_launcher_log
EOF
chmod 700 "$command_file"

# Snapshot Terminal.app's existing windows before Launch Services opens the
# dedicated .command session. The return transition clicks that exact new
# window's title bar instead of activating every Terminal window at once.
cat > "$terminal_window_focus_script" <<'SWIFT'
import AppKit
import CoreGraphics
import Foundation

let terminalBundleID = "com.apple.Terminal"
let mode = CommandLine.arguments.dropFirst().first ?? ""

func finderWindowIDs() -> [CGWindowID] {
  guard let finder = NSRunningApplication.runningApplications(
    withBundleIdentifier: "com.apple.finder"
  ).first,
  let entries = CGWindowListCopyWindowInfo(
    .optionAll, kCGNullWindowID
  ) as? [[String: Any]] else {
    return []
  }
  return entries.compactMap { entry in
    guard
      (entry[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == finder.processIdentifier,
      let number = (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value
    else {
      return nil
    }
    return number
  }
}

func terminalWindows() -> [(id: CGWindowID, bounds: CGRect, name: String)] {
  guard let terminal = NSRunningApplication.runningApplications(
    withBundleIdentifier: terminalBundleID
  ).first else {
    return []
  }
  guard let entries = CGWindowListCopyWindowInfo(
    .optionOnScreenOnly, kCGNullWindowID
  ) as? [[String: Any]] else {
    return []
  }

  return entries.compactMap { entry in
    guard
      (entry[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == terminal.processIdentifier,
      (entry[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
      let number = (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value,
      let boundsObject = entry[kCGWindowBounds as String] as? NSDictionary
    else {
      return nil
    }

    // Window-list values bridge through NSDictionary in Swift. Convert only
    // after the Objective-C dictionary cast; the conditional CFDictionary
    // cast is diagnosed as always successful by the current Swift compiler.
    let boundsDictionary = boundsObject as CFDictionary
    var bounds = CGRect.zero
    guard CGRectMakeWithDictionaryRepresentation(boundsDictionary, &bounds) else {
      return nil
    }
    let name = entry[kCGWindowName as String] as? String ?? "<untitled>"
    return (id: number, bounds: bounds, name: name)
  }
}

func logOnScreenWindowStack(click: CGPoint, targetID: CGWindowID) {
  guard let entries = CGWindowListCopyWindowInfo(
    .optionOnScreenOnly, kCGNullWindowID
  ) as? [[String: Any]] else {
    fputs("[macos-focus] Could not read the complete WindowServer on-screen window list.\n", stderr)
    return
  }

  let targetIndex = entries.firstIndex {
    (entry: [String: Any]) -> Bool in
    (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value == targetID
  }

  print("[macos-focus] WindowServer on-screen z-order (front-to-back), target=\(targetID), targetIndex=\(targetIndex.map { String($0) } ?? "not-found"), click=\(click)")
  var intersectingWindowsAboveTarget = 0

  for (index, entry) in entries.enumerated() {
    let windowID = (entry[kCGWindowNumber as String] as? NSNumber)?.uint32Value
    let owner = entry[kCGWindowOwnerName as String] as? String ?? "<unknown>"
    let ownerPID = (entry[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? -1
    let layer = (entry[kCGWindowLayer as String] as? NSNumber)?.intValue ?? -1
    let alpha = (entry[kCGWindowAlpha as String] as? NSNumber)?.doubleValue
    let name = entry[kCGWindowName as String] as? String ?? "<untitled>"

    var bounds: CGRect?
    if let boundsObject = entry[kCGWindowBounds as String] as? NSDictionary {
      let boundsDictionary = boundsObject as CFDictionary
      var rect = CGRect.zero
      if CGRectMakeWithDictionaryRepresentation(boundsDictionary, &rect) {
        bounds = rect
      }
    }

    let role: String
    if let targetIndex {
      if index < targetIndex {
        role = "ABOVE_TARGET"
      } else if index == targetIndex {
        role = "TARGET"
      } else {
        role = "BELOW_TARGET"
      }
    } else {
      role = "TARGET_NOT_FOUND"
    }

    let coversClick = bounds?.contains(click) ?? false
    let intersectsAboveTarget = role == "ABOVE_TARGET" && coversClick
    if intersectsAboveTarget {
      intersectingWindowsAboveTarget += 1
    }

    let boundsText = bounds.map { String(describing: $0) } ?? "<unavailable>"
    let alphaText = alpha.map { String($0) } ?? "<unavailable>"
    let clickText = coversClick ? "yes" : "no"
    let occluderText = intersectsAboveTarget ? "yes" : "no"
    print("[macos-focus] z[\(index)] role=\(role) id=\(windowID.map { String($0) } ?? "unknown") owner=\(owner) pid=\(ownerPID) layer=\(layer) alpha=\(alphaText) bounds=\(boundsText) name=\(name) coversClick=\(clickText) intersectsAboveTarget=\(occluderText)")
  }

  if targetIndex == nil {
    print("[macos-focus] TARGET WINDOW \(targetID) IS ABSENT from the on-screen WindowServer list.")
  }
  print("[macos-focus] WindowServer windows above target intersecting click point: \(intersectingWindowsAboveTarget)")
}

if mode == "snapshot" {
  print(terminalWindows().map { String($0.id) }.joined(separator: ","))
  exit(0)
}
if mode == "finder-snapshot" {
  print(finderWindowIDs().map { String($0) }.joined(separator: ","))
  exit(0)
}
if mode == "frontmost" {
  print(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown")
  exit(0)
}

guard mode == "activate", CommandLine.arguments.count == 3 else {
  fputs("Usage: terminal-window-focus.swift snapshot | finder-snapshot | frontmost | activate <previous-window-ids>\n", stderr)
  exit(2)
}

let previousIDs = Set(CommandLine.arguments[2].split(separator: ",").compactMap { UInt32($0) })
let candidates = terminalWindows().filter { !previousIDs.contains($0.id) }
guard candidates.count == 1, let target = candidates.first else {
  let details = terminalWindows().map {
    "id=\($0.id) name=\($0.name) bounds=\($0.bounds)"
  }.joined(separator: "; ")
  fputs("Expected exactly one new Terminal.app window for the Neovim TTY; found \(candidates.count). Windows: \(details)\n", stderr)
  exit(1)
}
guard target.bounds.width > 100, target.bounds.height > 80 else {
  fputs("Terminal.app target window has unusable bounds: \(target.bounds)\n", stderr)
  exit(1)
}
guard CGPreflightPostEventAccess() else {
  fputs("The runner cannot post a native mouse event to activate the Terminal.app window.\n", stderr)
  exit(1)
}
guard let source = CGEventSource(stateID: .combinedSessionState) else {
  fputs("Could not create a native mouse event source.\n", stderr)
  exit(1)
}

// Click inside the content area of the one window created for this test. A
// title-bar click can select the window without focusing the Terminal TTY view.
// This is a real WindowServer event, not a synthetic Neovim focus notification.
let contentPoint = CGPoint(x: target.bounds.midX, y: target.bounds.midY)
let mainDisplayBounds = CGDisplayBounds(CGMainDisplayID())
guard target.bounds.contains(contentPoint) else {
  fputs("Computed click point \(contentPoint) is outside Terminal.app window \(target.id) bounds \(target.bounds).\n", stderr)
  exit(1)
}
print("[macos-focus] WindowServer target: id=\(target.id) name=\(target.name) bounds=\(target.bounds); mainDisplay=\(mainDisplayBounds); click=\(contentPoint); sourceState=combinedSessionState; tap=cghidEventTap")
print("[macos-focus] Capturing complete WindowServer z-order immediately before posting the native click.")
logOnScreenWindowStack(click: contentPoint, targetID: target.id)
guard
  let mouseDown = CGEvent(
    mouseEventSource: source,
    mouseType: .leftMouseDown,
    mouseCursorPosition: contentPoint,
    mouseButton: .left
  ),
  let mouseUp = CGEvent(
    mouseEventSource: source,
    mouseType: .leftMouseUp,
    mouseCursorPosition: contentPoint,
    mouseButton: .left
  )
else {
  fputs("Could not construct native mouse events for Terminal.app window \(target.id).\n", stderr)
  exit(1)
}

mouseDown.post(tap: .cghidEventTap)
Thread.sleep(forTimeInterval: 0.05)
mouseUp.post(tap: .cghidEventTap)

let deadline = Date().addingTimeInterval(5)
while Date() < deadline {
  let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
  if frontmost == terminalBundleID, terminalWindows().first?.id == target.id {
    print("[macos-focus] Clicked and selected the exact Neovim Terminal.app window id=\(target.id) at \(contentPoint), bounds=\(target.bounds)")
    exit(0)
  }
  Thread.sleep(forTimeInterval: 0.1)
}

let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
fputs("Terminal.app window \(target.id) did not become the frontmost Terminal window after the native click; bounds=\(target.bounds), click=\(contentPoint), mainDisplay=\(mainDisplayBounds), frontmost app=\(frontmost).\n", stderr)
exit(1)
SWIFT

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


wait_for_terminal_tty() {
  local deadline=$((SECONDS + 10))
  while ((SECONDS < deadline)); do
    if [[ -s "$tty_file" ]]; then
      local target_tty
      target_tty="$(tr -d '\r\n' < "$tty_file")"
      [[ "$target_tty" == /dev/ttys* ]] || {
        printf 'Unexpected Neovim Terminal.app TTY: %s\n' "$target_tty" >&2
        return 1
      }
      printf '[macos-focus] Neovim is attached to Terminal.app TTY %s.\n' "$target_tty"
      return 0
    fi
    sleep 0.1
  done
  printf 'Terminal.app did not publish the Neovim session TTY within 10 seconds at %s\n' "$tty_file" >&2
  return 1
}
 

activate_and_wait_for_frontmost_application() {
  local bundle_id="$1"
  local app_name="$2"
  python3 - "$bundle_id" "$app_name" <<'PY'
import subprocess
import sys

bundle_id, app_name = sys.argv[1:3]
swift = """import AppKit
import Foundation

let bundleID = CommandLine.arguments[1]
let appName = CommandLine.arguments[2]
guard let application = NSRunningApplication.runningApplications(
  withBundleIdentifier: bundleID
).first else {
  fputs("Cannot activate \\(appName): application is not running.\\n", stderr)
  exit(1)
}

let activated = application.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
guard activated else {
  fputs("AppKit refused to activate \\(appName).\\n", stderr)
  exit(1)
}

let deadline = Date().addingTimeInterval(10)
while Date() < deadline {
  let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
  if frontmost == bundleID {
    print("[macos-focus] AppKit activated and verified \\(appName) (\\(bundleID))")
    exit(0)
  }
  RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}

let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown"
fputs("Expected \\(appName) (\\(bundleID)) to become frontmost; got \\(frontmost).\\n", stderr)
exit(1)
"""

try:
    result = subprocess.run(
        ["swift", "-", bundle_id, app_name],
        input=swift,
        text=True,
        check=False,
        timeout=30,
        capture_output=True,
    )
except subprocess.TimeoutExpired:
    print(f"AppKit activation for {app_name} exceeded its 30-second deadline", file=sys.stderr)
    raise SystemExit(124)

if result.stdout:
    print(result.stdout, end="")
if result.returncode != 0:
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="")
    raise SystemExit(result.returncode)
PY
}
close_new_finder_windows() {
  local previous_window_ids="$1"
  printf '[macos-focus] Closing only Finder windows created after the pre-activation snapshot: %s\n' "${previous_window_ids:-none}"
  osascript - "$previous_window_ids" <<'APPLESCRIPT'
on run argv
  set previousText to item 1 of argv
  set AppleScript's text item delimiters to ","
  if previousText is "" then
    set previousIDs to {}
  else
    set previousIDs to text items of previousText
  end if
  tell application "Finder"
    set windowsToClose to {}
    repeat with candidateWindow in every window
      set candidateID to (id of candidateWindow) as string
      if previousIDs does not contain candidateID then
        set end of windowsToClose to candidateWindow
      end if
    end repeat
    repeat with candidateWindow in windowsToClose
      close candidateWindow
    end repeat
  end tell
end run
APPLESCRIPT
}
assert_finder_frontmost() {
  local frontmost
  frontmost="$(swift "$terminal_window_focus_script" frontmost)"
  [[ "$frontmost" == "com.apple.finder" ]] || {
    printf '[macos-focus] Expected Finder to remain frontmost after closing test windows; got %s\n' "$frontmost" >&2
    return 1
  }
  printf '[macos-focus] Finder remains frontmost with test-created windows closed.\n'
}
activate_neovim_terminal_window() {
  local previous_window_ids="$1"
  swift "$terminal_window_focus_script" activate "$previous_window_ids"
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

terminal_windows_before="$(swift "$terminal_window_focus_script" snapshot)"
printf '[macos-focus] Terminal.app window IDs before test launch: %s\n' "${terminal_windows_before:-none}"
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
wait_for_terminal_tty

# Launch Services opened this .command in Terminal.app, but the hosted runner's
# initially active application is not guaranteed. Drive a complete activation
# cycle first so the test proves the Neovim TUI is attached to the window that
# actually receives keyboard focus, rather than assuming it was selected.
gained_before="$(read_counter dotfiles_macos_focus_gained)"
[[ "$gained_before" =~ ^[0-9]+$ ]] || {
  printf 'Neovim FocusGained counter was not initialized: %s\n' "$gained_before" >&2
  exit 1
}

printf '[macos-focus] Establishing the exact Neovim Terminal.app window as the focused starting point.\n'
activate_and_wait_for_frontmost_application "com.apple.Terminal" "Terminal.app"
activate_neovim_terminal_window "$terminal_windows_before"
printf '[macos-focus] Terminal.app is frontmost and the Neovim TTY window is selected before switching to Finder.\n'

lost_initial_before="$(read_counter dotfiles_macos_focus_lost)"
finder_windows_before="$(swift "$terminal_window_focus_script" finder-snapshot)"
printf '[macos-focus] Existing Finder window IDs before activation: %s\n' "${finder_windows_before:-none}"
printf '[macos-focus] Activating Finder using the previously validated direct Launch Services path.\n'
open -a Finder
wait_for_counter_gt dotfiles_macos_focus_lost "$lost_initial_before" \
  'Finder activation generated a real Neovim FocusLost event'
close_new_finder_windows "$finder_windows_before"
assert_finder_frontmost

printf '[macos-focus] Clicking the exact Neovim Terminal.app window and requiring a native FocusGained event.\n'
activate_neovim_terminal_window "$terminal_windows_before"
wait_for_counter_gt dotfiles_macos_focus_gained "$gained_before" \
  'Terminal.app activation generated a real Neovim FocusGained event'

lost_before="$(read_counter dotfiles_macos_focus_lost)"
finder_windows_before="$(swift "$terminal_window_focus_script" finder-snapshot)"
printf '[macos-focus] Existing Finder window IDs before second activation: %s\n' "${finder_windows_before:-none}"
printf '[macos-focus] Activating Finder using the previously validated direct Launch Services path.\n'
open -a Finder
wait_for_counter_gt dotfiles_macos_focus_lost "$lost_before" \
  'Finder activation generated a real Neovim FocusLost event on the second transition'
close_new_finder_windows "$finder_windows_before"
assert_finder_frontmost

gained_after="$(read_counter dotfiles_macos_focus_gained)"
printf '[macos-focus] Clicking the same Neovim Terminal.app window again and requiring another native FocusGained event.\n'
activate_neovim_terminal_window "$terminal_windows_before"
wait_for_counter_gt dotfiles_macos_focus_gained "$gained_after" \
  'Terminal.app reactivation generated a real Neovim FocusGained event'
lost_final="$(read_counter dotfiles_macos_focus_lost)"
gained_final="$(read_counter dotfiles_macos_focus_gained)"
printf '[macos-focus] Final native event counts: FocusLost=%s FocusGained=%s\n' \
  "$lost_final" "$gained_final"
printf 'PASS: macOS Terminal.app -> Finder -> Terminal.app focus transition reached Neovim through the real TUI PTY.\n'
