-- Verify Neovim's native focus-return timestamp check without running
-- :checktime on every buffer/window switch.
--
-- A small external MessagePack-RPC UI client attaches to the test Neovim and
-- sends the same nvim_ui_set_focus notifications used by Neovim's TUI.

local function write_external(path, lines)
  assert(vim.fn.writefile(lines, path) == 0, "could not write external fixture: " .. path)
end

local function buffer_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function assert_lines(buf, expected, label)
  local actual = buffer_lines(buf)
  assert(vim.deep_equal(expected, actual),
    ("%s: expected %s, got %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
end

local cleanup_test

local function fail_test(err)
  if cleanup_test then
    pcall(cleanup_test)
  end
  io.stderr:write("[checktime-focus] " .. tostring(err) .. "\n")
  io.stderr:flush()
  vim.cmd("cquit 1")
end

local function send_user_motion(win, key)
  vim.api.nvim_set_current_win(win)
  local before = vim.api.nvim_win_get_cursor(win)
  local encoded = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(encoded, "mtx", false)
  local after_ok, after = pcall(vim.api.nvim_win_get_cursor, win)
  assert(after_ok and after[1] == before[1] and after[2] ~= before[2],
    ("real %q input did not move the cursor: before=%s after=%s"):format(
      key, vim.inspect(before), vim.inspect(after_ok and after or nil)))
end

local function run()
  local path = vim.fn.tempname() .. ".txt"
  local group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })
  local server_address
  local ui_job
  local ui_script_path
  local ui_exit_code
  local ui_ready = false
  local ui_stdout = {}
  local ui_stderr = {}
  local ui_enter_events = 0
  local focus_gained_events = 0
  local focus_lost_events = 0
  local changed_events = {}
  local focus_history = {}
  local buffer_entry_events = 0
  local test_started_at = vim.uv.hrtime()
  local last_focus_at

  local function cleanup()
    -- Ask the RPC client to exit cleanly so its socket detaches the UI.
    if ui_job and ui_job > 0 then
      pcall(vim.fn.chansend, ui_job, "QUIT\n")
      local waited = vim.fn.jobwait({ ui_job }, 1000)
      if waited and waited[1] == -1 then
        pcall(vim.fn.jobstop, ui_job)
        pcall(vim.fn.jobwait, { ui_job }, 1000)
      end
    end
    if server_address then
      pcall(vim.fn.serverstop, server_address)
    end
    if ui_script_path then
      vim.fn.delete(ui_script_path)
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.fn.delete(path)
  end
  cleanup_test = cleanup

  local function safe_step(callback)
    local ok, err = xpcall(callback, debug.traceback)
    if not ok then
      fail_test(err)
    end
  end

  -- Poll with timers instead of blocking vim.wait(). The parent Neovim must
  -- keep processing its RPC socket while the external UI is attaching and
  -- while focus notifications are arriving.
  local function poll_until(label, predicate, timeout_ms, callback)
    local deadline = vim.uv.hrtime() + timeout_ms * 1000000
    local function poll()
      local ok, ready = pcall(predicate)
      if not ok then
        callback(false, ("%s predicate failed: %s"):format(label, tostring(ready)))
        return
      end
      if ready then
        callback(true)
        return
      end
      if ui_exit_code ~= nil then
        callback(false, ("%s: RPC UI client exited with code %s; stdout=%s stderr=%s"):format(
          label, vim.inspect(ui_exit_code), vim.inspect(ui_stdout), vim.inspect(ui_stderr)))
        return
      end
      if vim.uv.hrtime() >= deadline then
        callback(false, ("timed out waiting for %s; stdout=%s stderr=%s"):format(
          label, vim.inspect(ui_stdout), vim.inspect(ui_stderr)))
        return
      end
      vim.defer_fn(poll, 10)
    end
    poll()
  end

  local function trigger_native_focus_cycle(label, callback)
    local before_lost = focus_lost_events
    local before_gained = focus_gained_events
    local sent = vim.fn.chansend(ui_job, "FOCUS\n")
    if sent ~= 6 then
      callback(false, ("%s: RPC UI client accepted %s/6 focus command bytes; stderr=%s"):format(
        label, vim.inspect(sent), vim.inspect(ui_stderr)))
      return
    end

    poll_until(label .. " native FocusLost", function()
      return focus_lost_events == before_lost + 1
    end, 2000, function(lost, lost_error)
      if not lost then
        callback(false, lost_error)
        return
      end

      poll_until(label .. " native FocusGained", function()
        return focus_gained_events == before_gained + 1
      end, 2000, function(gained, gained_error)
        if not gained then
          callback(false, gained_error)
          return
        end
        last_focus_at = vim.uv.hrtime()
        callback(true)
      end)
    end)
  end

  local function gain_native_focus(label, callback)
    -- Neovim v0.12.6 throttles native timestamp checks to once per 2000ms.
    local anchor = last_focus_at or test_started_at
    local elapsed = vim.uv.hrtime() - anchor
    local remaining_ms = math.max(0, math.ceil((2100000000 - elapsed) / 1000000))
    vim.defer_fn(function()
      trigger_native_focus_cycle(label, callback)
    end, remaining_ms)
  end

  local focus_buf
  local focus_win
  local switch_win_a
  local switch_win_b
  local switch_buf_a
  local switch_buf_b
  local spare_buf_a
  local spare_buf_b

  local function finish_successfully()
    cleanup()
    cleanup_test = nil
    print("PASS: native checktime focus policy and real UI behavior")
    vim.cmd("qa!")
  end

  local function stage_conflict()
    send_user_motion(switch_win_a, "l")
    vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, { "local unsaved edit" })
    assert(vim.bo[focus_buf].modified == true, "local fixture edit did not mark the buffer modified")
    write_external(path, { "conflicting external disk version" })
    local before_conflict = #changed_events

    gain_native_focus("modified-buffer conflict focus return", function(ok, err)
      if not ok then
        fail_test(err)
        return
      end
      safe_step(function()
        assert(#changed_events == before_conflict + 1,
          ("native focus return should report a modified-buffer conflict: %s"):format(
            vim.inspect(changed_events)))
        assert(changed_events[#changed_events].reason == "conflict",
          "modified buffer should report a FileChangedShell conflict")
        assert_lines(focus_buf, { "local unsaved edit" },
          "external changes must not overwrite local unsaved edits")
        assert(vim.bo[focus_buf].modified == true,
          "external conflict unexpectedly cleared the modified flag")
        print("PASS: native FocusGained preserves unsaved local edits on external conflict")
        finish_successfully()
      end)
    end)
  end

  local function stage_second_external_change()
    local unchanged_event_count = #changed_events
    send_user_motion(switch_win_a, "l")
    write_external(path, {
      "disk version three, second external change",
      "third version still has two lines",
    })

    gain_native_focus("second external change focus return", function(ok, err)
      if not ok then
        fail_test(err)
        return
      end
      safe_step(function()
        assert(#changed_events == unchanged_event_count + 1,
          ("next focus return should detect the later external change: %s"):format(
            vim.inspect(changed_events)))
        assert(changed_events[#changed_events].reason == "changed",
          "second clean external change should be reported as changed")
        assert_lines(focus_buf, {
          "disk version three, second external change",
          "third version still has two lines",
        }, "second native FocusGained reload")
        print("PASS: a later external change is detected on the next focus return")
        stage_conflict()
      end)
    end)
  end

  local function stage_first_external_change()
    send_user_motion(switch_win_a, "l")
    local focus_gains_before_switch = focus_gained_events
    local focus_losses_before_switch = focus_lost_events
    write_external(path, {
      "disk version two after focus loss",
      "second line proves content changed",
    })

    -- Keep changing buffers in the two switch windows while the externally
    -- modified file remains visible in a third, inactive window.
    for _ = 1, 4 do
      vim.api.nvim_set_current_win(switch_win_a)
      vim.api.nvim_win_set_buf(switch_win_a, spare_buf_a)
      vim.api.nvim_win_set_buf(switch_win_a, switch_buf_a)
      vim.api.nvim_set_current_win(switch_win_b)
      vim.api.nvim_win_set_buf(switch_win_b, spare_buf_b)
      vim.api.nvim_win_set_buf(switch_win_b, switch_buf_b)
    end
    assert(buffer_entry_events >= 8,
      ("expected repeated real BufWinEnter events in the two switch windows, observed %d"):format(
        buffer_entry_events))
    assert(vim.api.nvim_get_current_win() ~= focus_win
        and vim.api.nvim_win_get_buf(focus_win) == focus_buf,
      "the changed focus buffer became current during the window-switch scenario")
    assert(focus_gained_events == focus_gains_before_switch
        and focus_lost_events == focus_losses_before_switch,
      ("a focus transition occurred during buffer/window switching; gained=%d->%d lost=%d->%d history=%s"):format(
        focus_gains_before_switch, focus_gained_events,
        focus_losses_before_switch, focus_lost_events, vim.inspect(focus_history)))
    assert(#changed_events == 0,
      ("switching buffers/windows scanned another visible file unexpectedly: events=%s focus_history=%s"):format(
        vim.inspect(changed_events), vim.inspect(focus_history)))
    assert_lines(focus_buf, { "disk version one" },
      "unrelated buffer/window activity must not check a different visible file")
    print("PASS: real BufWinEnter and window switching do not scan other visible files")

    gain_native_focus("first external change focus return", function(ok, err)
      if not ok then
        fail_test(err)
        return
      end
      safe_step(function()
        assert(#changed_events == 1,
          ("one native focus return should detect exactly one external change: %s"):format(
            vim.inspect(changed_events)))
        assert(changed_events[1].buffer == focus_buf, "FocusGained reported the wrong buffer")
        assert(changed_events[1].reason == "changed",
          "FocusGained should report a clean external change, got " .. tostring(changed_events[1].reason))
        assert_lines(focus_buf, {
          "disk version two after focus loss",
          "second line proves content changed",
        }, "native FocusGained reload")
        print("PASS: native FocusGained detects and reloads an external change")
        stage_second_external_change()
      end)
    end)
  end

  local function stage_unchanged_file()
    send_user_motion(switch_win_a, "l")
    gain_native_focus("unchanged-file focus return", function(ok, err)
      if not ok then
        fail_test(err)
        return
      end
      safe_step(function()
        assert(#changed_events == 0,
          ("an unchanged file produced a focus-change event: %s"):format(vim.inspect(changed_events)))
        print("PASS: native focus checks do not report unchanged files")
        stage_first_external_change()
      end)
    end)
  end

  local function setup_behavior_fixture()
    -- Use autoread=false only for this isolated fixture so the native focus
    -- timestamp check reports FileChangedShell and we can assert its result.
    write_external(path, { "disk version one" })
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    focus_buf = vim.api.nvim_get_current_buf()
    vim.bo[focus_buf].autoread = false
    assert(vim.bo[focus_buf].autoread == false,
      "focus fixture failed to disable autoread locally")

    vim.api.nvim_create_autocmd("FileChangedShell", {
      group = group,
      callback = function(event)
        local reason = vim.v.fcs_reason
        changed_events[#changed_events + 1] = {
          buffer = event.buf,
          file = event.file,
          reason = reason,
          focus_gained_events = focus_gained_events,
          focus_lost_events = focus_lost_events,
          buffer_entry_events = buffer_entry_events,
          at = vim.uv.hrtime(),
        }
        -- Reload clean external changes, but never discard unsaved local edits.
        vim.v.fcs_choice = reason == "conflict" and "" or "reload"
      end,
    })

    -- The changed file stays visible in an inactive window. A global
    -- :checktime on BufWinEnter would still discover it during unrelated
    -- window/buffer entries; native focus checks are exercised separately.
    focus_win = vim.api.nvim_get_current_win()
    vim.cmd("vsplit")
    switch_win_a = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    switch_buf_a = vim.api.nvim_get_current_buf()
    vim.cmd("vsplit")
    switch_win_b = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    switch_buf_b = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(switch_buf_a, 0, -1, false, { "cursor movement fixture" })
    vim.api.nvim_win_set_cursor(switch_win_a, { 1, 0 })
    assert(focus_win ~= switch_win_a and focus_win ~= switch_win_b and switch_win_a ~= switch_win_b,
      "window-switch fixture did not create three independent windows")
    assert(vim.api.nvim_win_get_buf(focus_win) == focus_buf,
      "externally modified focus buffer is not isolated in its own window")

    spare_buf_a = vim.api.nvim_create_buf(false, true)
    spare_buf_b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(event)
        if event.buf == switch_buf_a or event.buf == switch_buf_b
            or event.buf == spare_buf_a or event.buf == spare_buf_b then
          buffer_entry_events = buffer_entry_events + 1
        end
      end,
    })

    stage_unchanged_file()
  end

  local function start_behavior_tests()
    print("PASS: attached a real external MessagePack-RPC UI channel")
    trigger_native_focus_cycle("initial native RPC UI focus cycle", function(ok, err)
      if not ok then
        fail_test(err)
        return
      end
      print("PASS: initial native focus-loss/focus-gain notifications were observed")
      safe_step(setup_behavior_fixture)
    end)
  end

  print("INFO: checktime-focus entered; starting parent RPC server")
  server_address = vim.fn.serverstart()
  assert(type(server_address) == "string" and server_address ~= "",
    "serverstart() did not return a Neovim RPC address")
  print("INFO: parent RPC server listening at " .. server_address)

  vim.api.nvim_create_autocmd("UIEnter", {
    group = group,
    callback = function()
      ui_enter_events = ui_enter_events + 1
    end,
  })
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      focus_lost_events = focus_lost_events + 1
      focus_history[#focus_history + 1] = {
        event = "FocusLost",
        at = vim.uv.hrtime(),
        buffer = vim.api.nvim_get_current_buf(),
      }
    end,
  })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      focus_gained_events = focus_gained_events + 1
      focus_history[#focus_history + 1] = {
        event = "FocusGained",
        at = vim.uv.hrtime(),
        buffer = vim.api.nvim_get_current_buf(),
      }
    end,
  })

  local ui_client_script = [=[
import os
import socket
import struct
import sys
import traceback

def pack(value):
    if value is None:
        return b"\xc0"
    if value is False:
        return b"\xc2"
    if value is True:
        return b"\xc3"
    if isinstance(value, int):
        if 0 <= value <= 0x7f:
            return bytes((value,))
        if -32 <= value < 0:
            return bytes((value & 0xff,))
        if 0 <= value <= 0xff:
            return b"\xcc" + struct.pack(">B", value)
        if -0x80 <= value < 0:
            return b"\xd0" + struct.pack(">b", value)
        if 0 <= value <= 0xffff:
            return b"\xcd" + struct.pack(">H", value)
        if -0x8000 <= value < 0:
            return b"\xd1" + struct.pack(">h", value)
        if 0 <= value <= 0xffffffff:
            return b"\xce" + struct.pack(">I", value)
        if -0x80000000 <= value < 0:
            return b"\xd2" + struct.pack(">i", value)
        if value >= 0:
            return b"\xcf" + struct.pack(">Q", value)
        return b"\xd3" + struct.pack(">q", value)
    if isinstance(value, str):
        data = value.encode("utf-8")
        size = len(data)
        if size <= 31:
            return bytes((0xa0 | size,)) + data
        if size <= 0xff:
            return b"\xd9" + struct.pack(">B", size) + data
        if size <= 0xffff:
            return b"\xda" + struct.pack(">H", size) + data
        return b"\xdb" + struct.pack(">I", size) + data
    if isinstance(value, (list, tuple)):
        size = len(value)
        if size <= 15:
            head = bytes((0x90 | size,))
        elif size <= 0xffff:
            head = b"\xdc" + struct.pack(">H", size)
        else:
            head = b"\xdd" + struct.pack(">I", size)
        return head + b"".join(pack(item) for item in value)
    if isinstance(value, dict):
        size = len(value)
        if size <= 15:
            head = bytes((0x80 | size,))
        elif size <= 0xffff:
            head = b"\xde" + struct.pack(">H", size)
        else:
            head = b"\xdf" + struct.pack(">I", size)
        return head + b"".join(pack(k) + pack(v) for k, v in value.items())
    raise TypeError("unsupported MessagePack value: " + type(value).__name__)

def read_exact(sock, size):
    chunks = []
    remaining = size
    while remaining:
        chunk = sock.recv(remaining)
        if not chunk:
            raise EOFError("Neovim RPC socket closed while reading MessagePack data")
        chunks.append(chunk)
        remaining -= len(chunk)
    return b"".join(chunks)

def unpack(sock):
    first = read_exact(sock, 1)[0]
    if first <= 0x7f:
        return first
    if first >= 0xe0:
        return first - 256
    if 0x80 <= first <= 0x8f:
        return {unpack(sock): unpack(sock) for _ in range(first & 0x0f)}
    if 0x90 <= first <= 0x9f:
        return [unpack(sock) for _ in range(first & 0x0f)]
    if 0xa0 <= first <= 0xbf:
        return read_exact(sock, first & 0x1f).decode("utf-8")
    if first == 0xc0:
        return None
    if first == 0xc2:
        return False
    if first == 0xc3:
        return True
    if first == 0xca:
        return struct.unpack(">f", read_exact(sock, 4))[0]
    if first == 0xcb:
        return struct.unpack(">d", read_exact(sock, 8))[0]
    if first == 0xc4:
        return read_exact(sock, struct.unpack(">B", read_exact(sock, 1))[0])
    if first == 0xc5:
        return read_exact(sock, struct.unpack(">H", read_exact(sock, 2))[0])
    if first == 0xc6:
        return read_exact(sock, struct.unpack(">I", read_exact(sock, 4))[0])
    if first in (0xcc, 0xcd, 0xce, 0xcf):
        formats = {0xcc: ">B", 0xcd: ">H", 0xce: ">I", 0xcf: ">Q"}
        fmt = formats[first]
        return struct.unpack(fmt, read_exact(sock, struct.calcsize(fmt)))[0]
    if first in (0xd0, 0xd1, 0xd2, 0xd3):
        formats = {0xd0: ">b", 0xd1: ">h", 0xd2: ">i", 0xd3: ">q"}
        fmt = formats[first]
        return struct.unpack(fmt, read_exact(sock, struct.calcsize(fmt)))[0]
    if first in (0xd9, 0xda, 0xdb):
        formats = {0xd9: ">B", 0xda: ">H", 0xdb: ">I"}
        fmt = formats[first]
        size = struct.unpack(fmt, read_exact(sock, struct.calcsize(fmt)))[0]
        return read_exact(sock, size).decode("utf-8")
    if first in (0xdc, 0xdd):
        fmt = ">H" if first == 0xdc else ">I"
        size = struct.unpack(fmt, read_exact(sock, struct.calcsize(fmt)))[0]
        return [unpack(sock) for _ in range(size)]
    if first in (0xde, 0xdf):
        fmt = ">H" if first == 0xde else ">I"
        size = struct.unpack(fmt, read_exact(sock, struct.calcsize(fmt)))[0]
        return {unpack(sock): unpack(sock) for _ in range(size)}
    if first in (0xc7, 0xc8, 0xc9, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8):
        if first == 0xc7:
            size = struct.unpack(">B", read_exact(sock, 1))[0]
        elif first == 0xc8:
            size = struct.unpack(">H", read_exact(sock, 2))[0]
        elif first == 0xc9:
            size = struct.unpack(">I", read_exact(sock, 4))[0]
        else:
            size = {0xd4: 1, 0xd5: 2, 0xd6: 4, 0xd7: 8, 0xd8: 16}[first]
        read_exact(sock, 1)  # extension type
        return read_exact(sock, size)
    raise ValueError("unsupported MessagePack marker: 0x%02x" % first)

def connect(address):
    if os.name != "nt" and address.startswith("/"):
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        connection.connect(address)
        return connection
    if ":" in address:
        host, port = address.rsplit(":", 1)
        connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        connection.connect((host, int(port)))
        return connection
    raise ValueError("unsupported Neovim RPC address: " + address)

def main():
    address = sys.argv[1]
    connection = connect(address)
    connection.settimeout(5.0)
    connection.sendall(pack([0, 1, "nvim_ui_attach", [80, 24, {"rgb": True}]]))

    # UI attachment can produce redraw notifications before the request reply.
    while True:
        message = unpack(connection)
        if isinstance(message, list) and len(message) >= 4 and message[0] == 1 and message[1] == 1:
            if message[2] is not None:
                raise RuntimeError("nvim_ui_attach failed: " + repr(message[2]))
            break

    print("READY", flush=True)
    for command in sys.stdin:
        command = command.strip()
        if command == "FOCUS":
            connection.sendall(pack([2, "nvim_ui_set_focus", [False]]))
            connection.sendall(pack([2, "nvim_ui_set_focus", [True]]))
        elif command == "QUIT":
            break
    connection.close()

if __name__ == "__main__":
    try:
        main()
    except Exception:
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
  ]=]
  assert(vim.fn.writefile(vim.split(ui_client_script, "\n"), ui_script_path) == 0,
    "could not write the Python RPC UI client")

  local python = vim.fn.exepath("python3")
  assert(python ~= "", "python3 is required for the native RPC UI integration fixture")
  print("INFO: starting external MessagePack-RPC UI client")
  ui_job = vim.fn.jobstart({ python, "-u", ui_script_path, server_address }, {
    on_stdout = function(_, data)
      for _, line in ipairs(data) do
        if line == "READY" then
          ui_ready = true
        elseif line ~= "" then
          ui_stdout[#ui_stdout + 1] = line
        end
      end
    end,
    on_stderr = function(_, data)
      for _, line in ipairs(data) do
        if line ~= "" then
          ui_stderr[#ui_stderr + 1] = line
        end
      end
    end,
    on_exit = function(_, code)
      ui_exit_code = code
    end,
  })
  assert(type(ui_job) == "number" and ui_job > 0,
    ("could not start the Python RPC UI client: %s"):format(vim.inspect(ui_job)))
  print("INFO: external RPC UI client started as job " .. ui_job .. "; waiting for UIEnter")

  poll_until("external MessagePack-RPC UI attach", function()
    return ui_ready and ui_enter_events == 1
  end, 5000, function(ok, err)
    if not ok then
      fail_test(("%s; UIEnter=%d stdout=%s stderr=%s"):format(
        tostring(err), ui_enter_events, vim.inspect(ui_stdout), vim.inspect(ui_stderr)))
      return
    end
    safe_step(start_behavior_tests)
  end)
end

vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    fail_test(err)
  end
end, 10)
