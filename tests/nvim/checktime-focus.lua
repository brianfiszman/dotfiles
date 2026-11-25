-- Verify native focus-return timestamp checks using Neovim's real TUI input path.

-- Plugin restore can leave an existing hit-enter prompt; prevent new pagers
-- from interrupting the real TUI input once the test starts.
vim.o.more = false
--
-- The parent Neovim runs under a PTY. A small external driver sends the same
-- focus-reporting escape sequences a terminal emulator sends after focus
-- changes; Neovim's own TUI parser must turn them into FocusLost/FocusGained.

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

local function check(label, expected, actual)
  assert(vim.deep_equal(expected, actual),
    ("%s: expected %s, got %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  print("PASS: " .. label)
end

local cleanup_test

local function fail_test(err)
  if cleanup_test then
    pcall(cleanup_test)
    cleanup_test = nil
  end
  io.stderr:write("[checktime-focus] " .. tostring(err) .. "\n")
  io.stderr:flush()
  vim.cmd("cquit 1")
end

local function send_user_motion(win, key)
  vim.api.nvim_set_current_win(win)
  local before = vim.api.nvim_win_get_cursor(win)
  local accepted = vim.api.nvim_input(key)
  assert(accepted == #key,
    ("Neovim accepted %d/%d user-activity bytes for %q"):format(accepted, #key, key))

  -- nvim_input() queues typeahead. Yield this test coroutine so Neovim's real
  -- Normal-mode loop consumes the key and resets did_check_timestamps before
  -- the next PTY focus cycle is delivered.
  local thread = assert(coroutine.running(), "user activity must run in the test coroutine")
  vim.defer_fn(function()
    local read_ok, after = pcall(vim.api.nvim_win_get_cursor, win)
    local moved = read_ok and after[1] == before[1] and after[2] ~= before[2]
    local resumed, resume_error = coroutine.resume(thread, moved, read_ok and after or nil)
    if not resumed then
      fail_test(debug.traceback(thread, tostring(resume_error)))
    end
  end, 20)

  local moved, after = coroutine.yield()
  assert(moved,
    ("user-activity key %q did not move the cursor: before=%s after=%s mode=%s current_win=%s target_win=%s current_buf=%s target_buf=%s"):format(
      key, vim.inspect(before), vim.inspect(after), vim.fn.mode(),
      vim.api.nvim_get_current_win(), win,
      vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_buf(win)))
end

local function run()
  local path = vim.fn.tempname() .. ".txt"
  local group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })
  local control_fifo = vim.env.DOTFILES_FOCUS_CONTROL_FIFO
  local ui_count = #vim.api.nvim_list_uis()
  local test_started_at = vim.uv.hrtime()
  local last_focus_at
  local focus_gained_events = 0
  local focus_lost_events = 0
  local changed_events = {}
  local focus_history = {}
  local buffer_entry_events = 0

  assert(type(control_fifo) == "string" and control_fifo ~= "",
    "PTY focus driver did not provide DOTFILES_FOCUS_CONTROL_FIFO")
  check("test is running in a real Neovim TUI attached to a PTY", true, ui_count > 0)

  local function cleanup()
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.fn.delete(path)
  end
  cleanup_test = cleanup

  local function wait_for_focus_event(event_name, previous_count, timeout_ms)
    local predicate
    if event_name == "FocusLost" then
      predicate = function() return focus_lost_events == previous_count + 1 end
    else
      predicate = function() return focus_gained_events == previous_count + 1 end
    end

    local completed = vim.wait(timeout_ms, predicate, 10)
    local actual = event_name == "FocusLost" and focus_lost_events or focus_gained_events
    assert(completed,
      ("timed out waiting for PTY-delivered %s: expected count %d, got %d; history=%s"):format(
        event_name, previous_count + 1, actual, vim.inspect(focus_history)))
  end

  local function request_terminal_focus_event(command, event_name)
    local before = event_name == "FocusLost" and focus_lost_events or focus_gained_events
    local written = vim.fn.writefile({ command }, control_fifo)
    assert(written == 0,
      ("could not send %s to the PTY driver (writefile returned %s)"):format(
        command, vim.inspect(written)))

    wait_for_focus_event(event_name, before, 2000)
    print(("PASS: real TUI parsed terminal %s sequence"):format(event_name))
  end

  local function trigger_native_focus_cycle(label)
    request_terminal_focus_event("FOCUS_LOST", "FocusLost")
    request_terminal_focus_event("FOCUS_GAINED", "FocusGained")
    last_focus_at = vim.uv.hrtime()
    print("PASS: " .. label .. " reached Neovim's native focus-gained path")
  end

  local function gain_native_focus(label)
    -- Neovim 0.12.6 throttles timestamp checks to one per 2000ms.
    local anchor = last_focus_at or test_started_at
    local outside_throttle = vim.wait(2500, function()
      return vim.uv.hrtime() - anchor >= 2100000000
    end, 10)
    assert(outside_throttle,
      ("%s: native focus timestamp throttle did not expire after 2100ms"):format(label))
    trigger_native_focus_cycle(label)
  end

  local focus_buf
  local focus_win
  local switch_win_a
  local switch_win_b
  local switch_buf_a
  local switch_buf_b
  local spare_buf_a
  local spare_buf_b

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

  -- Prime the real PTY/TUI path before opening a changed file. The external
  -- driver refuses to send these bytes until it has observed Neovim request
  -- focus reporting with CSI ? 1004 h.
  trigger_native_focus_cycle("initial terminal focus cycle")

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

  -- Keep the changed file visible in an inactive window. The other two
  -- windows are switched repeatedly to distinguish ordinary BufWinEnter
  -- traffic from a global :checktime scan.
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

  -- An unchanged file should not report a change when real terminal focus
  -- returns to Neovim.
  send_user_motion(switch_win_a, "l")
  gain_native_focus("unchanged-file focus return")
  check("unchanged file produces no FileChangedShell event", 0, #changed_events)

  -- Modify the file externally, then switch buffers/windows repeatedly while
  -- the changed buffer remains visible but is not the current buffer.
  send_user_motion(switch_win_a, "l")
  local focus_gains_before_switch = focus_gained_events
  local focus_losses_before_switch = focus_lost_events
  write_external(path, {
    "disk version two after focus loss",
    "second line proves content changed",
  })

  for _ = 1, 4 do
    vim.api.nvim_set_current_win(switch_win_a)
    vim.api.nvim_win_set_buf(switch_win_a, spare_buf_a)
    vim.api.nvim_win_set_buf(switch_win_a, switch_buf_a)
    vim.api.nvim_set_current_win(switch_win_b)
    vim.api.nvim_win_set_buf(switch_win_b, spare_buf_b)
    vim.api.nvim_win_set_buf(switch_win_b, switch_buf_b)
  end
  assert(buffer_entry_events >= 8,
    ("expected at least eight real BufWinEnter events, observed %d"):format(buffer_entry_events))
  assert(vim.api.nvim_get_current_win() ~= focus_win
      and vim.api.nvim_win_get_buf(focus_win) == focus_buf,
    "the externally changed buffer became current during the window-switch scenario")
  check("buffer/window switching does not synthesize terminal focus events", {
    focus_losses_before_switch,
    focus_gains_before_switch,
  }, { focus_lost_events, focus_gained_events })
  check("buffer/window switching does not trigger FileChangedShell", 0, #changed_events)
  assert_lines(focus_buf, { "disk version one" },
    "unrelated buffer/window activity must not check a different visible file")
  print("PASS: real BufWinEnter and window switching do not scan other visible files")

  gain_native_focus("first external change focus return")
  check("first focus return reports exactly one external change", 1, #changed_events)
  check("first focus return reports the correct buffer", focus_buf, changed_events[1].buffer)
  check("first focus return reports a clean change", "changed", changed_events[1].reason)
  assert_lines(focus_buf, {
    "disk version two after focus loss",
    "second line proves content changed",
  }, "native TUI FocusGained reload")
  print("PASS: real TUI FocusGained detects and reloads an external change")

  -- A later external write is detected by the next real terminal focus cycle.
  local unchanged_event_count = #changed_events
  send_user_motion(switch_win_a, "l")
  write_external(path, {
    "disk version three, second external change",
    "third version still has two lines",
  })
  gain_native_focus("second external change focus return")
  check("next focus return reports the later external change",
    unchanged_event_count + 1, #changed_events)
  check("second external change reason", "changed", changed_events[#changed_events].reason)
  assert_lines(focus_buf, {
    "disk version three, second external change",
    "third version still has two lines",
  }, "second native TUI FocusGained reload")
  print("PASS: a later external change is detected on the next focus return")

  -- A conflict must be reported without replacing unsaved local content.
  send_user_motion(switch_win_a, "l")
  vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, { "local unsaved edit" })
  assert(vim.bo[focus_buf].modified == true,
    "local fixture edit did not mark the buffer modified")
  write_external(path, { "conflicting external disk version" })
  local before_conflict = #changed_events
  gain_native_focus("modified-buffer conflict focus return")
  check("modified-buffer focus return reports one conflict",
    before_conflict + 1, #changed_events)
  check("modified-buffer focus return reports conflict reason",
    "conflict", changed_events[#changed_events].reason)
  assert_lines(focus_buf, { "local unsaved edit" },
    "external conflict must not overwrite local unsaved edits")
  check("external conflict preserves the local modified flag", true, vim.bo[focus_buf].modified)
  print("PASS: real TUI FocusGained preserves unsaved local edits on external conflict")

  cleanup()
  cleanup_test = nil
end

local test_thread = coroutine.create(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    fail_test(err)
    return
  end

  print("PASS: PTY terminal focus reports preserve external-change detection without per-window :checktime")
  vim.cmd("qa!")
end)

vim.defer_fn(function()
  local ok, err = coroutine.resume(test_thread)
  if not ok then
    fail_test(debug.traceback(test_thread, tostring(err)))
  end
end, 10)
