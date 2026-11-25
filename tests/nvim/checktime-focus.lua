-- Verify native focus-return timestamp checks using Neovim's real TUI input path.
-- Each scenario runs in a fresh Neovim process so it gets exactly one native
-- FocusGained timestamp check; no synthetic keyboard input is needed to reset
-- Neovim's per-session did_check_timestamps guard.

vim.o.more = false

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

local function run()
  local scenario = vim.env.DOTFILES_FOCUS_SCENARIO
  local allowed = {
    unchanged = true,
    external_change = true,
    conflict = true,
    buffer_switch = true,
  }
  assert(allowed[scenario], "unknown DOTFILES_FOCUS_SCENARIO: " .. tostring(scenario))

  local path = vim.fn.tempname() .. ".txt"
  local group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })
  local control_fifo = vim.env.DOTFILES_FOCUS_CONTROL_FIFO
  local ui_count = #vim.api.nvim_list_uis()
  local focus_gained_events = 0
  local focus_lost_events = 0
  local focus_history = {}
  local changed_events = {}
  local buffer_entry_events = 0

  assert(type(control_fifo) == "string" and control_fifo ~= "",
    "PTY focus driver did not provide DOTFILES_FOCUS_CONTROL_FIFO")
  check("scenario " .. scenario .. " runs in a real Neovim TUI attached to a PTY", true, ui_count > 0)

  -- Keep this test focused on real terminal focus input and checktime. LSP
  -- package installation is covered by normal startup/LuaLS integration and
  -- is intentionally suppressed only in these short-lived focus processes.
  local lsp = require("lsp.config")
  assert(vim.wait(5000, function()
    return type(lsp.mason_options) == "table" and type(lsp.enabled_servers) == "table"
  end, 10), "native LSP configuration did not finish before focus assertions")
  check("focus PTY skips unrelated Mason package installation", {}, lsp.mason_options.ensure_installed)
  check("focus PTY still explicitly enables configured native LSP servers",
    lsp.servers, lsp.enabled_servers)

  local function cleanup()
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.fn.delete(path)
  end
  cleanup_test = cleanup

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

  local function wait_for_focus_event(event_name, previous_count)
    local predicate
    if event_name == "FocusLost" then
      predicate = function() return focus_lost_events == previous_count + 1 end
    else
      predicate = function() return focus_gained_events == previous_count + 1 end
    end

    local completed = vim.wait(2000, predicate, 10)
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

    wait_for_focus_event(event_name, before)
    print(("PASS: real TUI parsed terminal %s sequence"):format(event_name))
  end

  local function trigger_native_focus_cycle()
    request_terminal_focus_event("FOCUS_LOST", "FocusLost")
    request_terminal_focus_event("FOCUS_GAINED", "FocusGained")
    check("scenario receives exactly one native terminal focus-loss event", 1, focus_lost_events)
    check("scenario receives exactly one native terminal focus-gain event", 1, focus_gained_events)
  end

  -- Open the file before the first FocusGained event in this process. The
  -- first native focus return therefore exercises check_timestamps(true)
  -- without requiring a user keystroke to reset the per-session guard.
  write_external(path, { "disk version one" })
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  local focus_buf = vim.api.nvim_get_current_buf()
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
      }
      -- Reload clean external changes, but never discard unsaved local edits.
      vim.v.fcs_choice = reason == "conflict" and "" or "reload"
    end,
  })

  if scenario == "unchanged" then
    trigger_native_focus_cycle()
    check("unchanged file produces no FileChangedShell event", 0, #changed_events)
    assert_lines(focus_buf, { "disk version one" }, "unchanged native focus check")

  elseif scenario == "external_change" then
    write_external(path, {
      "disk version two after terminal focus loss",
      "second line proves external content changed",
    })
    trigger_native_focus_cycle()
    check("native focus return reports one external change", 1, #changed_events)
    check("native focus return reports the correct buffer", focus_buf, changed_events[1].buffer)
    check("native focus return reports a clean change", "changed", changed_events[1].reason)
    assert_lines(focus_buf, {
      "disk version two after terminal focus loss",
      "second line proves external content changed",
    }, "native TUI FocusGained reload")

  elseif scenario == "conflict" then
    vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, { "local unsaved edit" })
    assert(vim.bo[focus_buf].modified == true,
      "local fixture edit did not mark the buffer modified")
    write_external(path, { "conflicting external disk version" })
    trigger_native_focus_cycle()
    check("modified-buffer focus return reports one conflict", 1, #changed_events)
    check("modified-buffer focus return reports conflict reason", "conflict", changed_events[1].reason)
    assert_lines(focus_buf, { "local unsaved edit" },
      "external conflict must not overwrite local unsaved edits")
    check("external conflict preserves the local modified flag", true, vim.bo[focus_buf].modified)

  elseif scenario == "buffer_switch" then
    -- Keep the changed file visible in an inactive window. Repeated real
    -- BufWinEnter events in other windows must not scan it. A terminal focus
    -- return must then discover and reload that same visible buffer.
    local focus_win = vim.api.nvim_get_current_win()
    vim.cmd("vsplit")
    local switch_win_a = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    local switch_buf_a = vim.api.nvim_get_current_buf()
    vim.cmd("vsplit")
    local switch_win_b = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    local switch_buf_b = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(switch_buf_a, 0, -1, false, { "window switch fixture" })
    assert(focus_win ~= switch_win_a and focus_win ~= switch_win_b
        and switch_win_a ~= switch_win_b,
      "window-switch fixture did not create three independent windows")
    assert(vim.api.nvim_win_get_buf(focus_win) == focus_buf,
      "externally monitored buffer is not visible in its own window")

    local spare_buf_a = vim.api.nvim_create_buf(false, true)
    local spare_buf_b = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(event)
        if event.buf == switch_buf_a or event.buf == switch_buf_b
            or event.buf == spare_buf_a or event.buf == spare_buf_b then
          buffer_entry_events = buffer_entry_events + 1
        end
      end,
    })

    write_external(path, {
      "disk version after unrelated window switches",
      "visible inactive buffer must wait for terminal focus return",
    })
    local focus_gains_before_switch = focus_gained_events
    local focus_losses_before_switch = focus_lost_events
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
      focus_losses_before_switch, focus_gains_before_switch,
    }, { focus_lost_events, focus_gained_events })
    check("buffer/window switching does not trigger FileChangedShell", 0, #changed_events)
    assert_lines(focus_buf, { "disk version one" },
      "unrelated buffer/window activity must not scan the inactive visible file")

    trigger_native_focus_cycle()
    check("terminal focus return discovers the inactive visible external change", 1, #changed_events)
    check("inactive visible buffer is the one reported changed", focus_buf, changed_events[1].buffer)
    check("inactive visible buffer is reported as a clean change", "changed", changed_events[1].reason)
    assert_lines(focus_buf, {
      "disk version after unrelated window switches",
      "visible inactive buffer must wait for terminal focus return",
    }, "inactive visible buffer reload after TUI FocusGained")
  end

  cleanup()
  cleanup_test = nil
  print("PASS: PTY focus scenario " .. scenario)
end

vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    fail_test(err)
    return
  end
  print("PASS: automated PTY terminal-focus regression scenario")
  vim.cmd("qa!")
end, 10)
