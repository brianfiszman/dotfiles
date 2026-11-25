-- Verify Neovim's native focus-return timestamp check without running
-- :checktime on every buffer/window switch.
--
-- A minimal RPC UI client sends the native focus notifications that Neovim's
-- TUI emits after parsing terminal focus-reporting sequences.

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

local function wait_for(label, predicate, timeout_ms)
  assert(vim.wait(timeout_ms, predicate, 10),
    ("timed out waiting for %s; current state: %s"):format(label, vim.inspect({
      mode = vim.fn.mode(),
      current_buffer = vim.api.nvim_get_current_buf(),
    })))
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
  local accepted = vim.api.nvim_input(key)
  assert(accepted == #key,
    ("Neovim accepted %d/%d input bytes for key %q"):format(accepted, #key, key))

  -- Keep this test on Neovim's main Lua thread. vim.wait() pumps the real
  -- input loop, avoiding timer-driven coroutine resumption in the headless run.
  local moved = vim.wait(1000, function()
    local read_ok, after = pcall(vim.api.nvim_win_get_cursor, win)
    return read_ok and after[1] == before[1] and after[2] ~= before[2]
  end, 10)
  local after_ok, after = pcall(vim.api.nvim_win_get_cursor, win)
  assert(moved,
    ("real %q input did not move the cursor: before=%s after=%s"):format(
      key, vim.inspect(before), vim.inspect(after_ok and after or nil)))
end

local function run()
  local path = vim.fn.tempname() .. ".txt"
  local group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })
  local server_address
  local ui_job
  local ui_exit_code
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
    -- Stop the RPC UI client before closing the server socket.
    if ui_job and ui_job > 0 then
      pcall(vim.fn.jobstop, ui_job)
      pcall(vim.fn.jobwait, { ui_job }, 1500)
    end
    if server_address then
      pcall(vim.fn.serverstop, server_address)
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.fn.delete(path)
  end
  cleanup_test = cleanup

  local function trigger_native_focus_cycle(label)
    local before_lost = focus_lost_events
    local before_gained = focus_gained_events
    vim.g.dotfiles_checktime_focus_error = nil
    local lua = [[
      local channel = _G.dotfiles_checktime_focus_parent_channel
      local ok, err = xpcall(function()
        assert(type(channel) == "number" and channel > 0,
          "RPC UI client is not connected to the parent Neovim")
        assert(vim.rpcnotify(channel, "nvim_ui_set_focus", false),
          "could not send native FocusLost notification")
        assert(vim.rpcnotify(channel, "nvim_ui_set_focus", true),
          "could not send native FocusGained notification")
      end, debug.traceback)
      if not ok and type(channel) == "number" then
        vim.rpcnotify(channel, "nvim_set_var", "dotfiles_checktime_focus_error", tostring(err))
      elseif not ok then
        io.stderr:write("[checktime-focus-client] " .. tostring(err) .. "\n")
        io.stderr:flush()
      end
    ]]
    assert(vim.rpcnotify(ui_job, "nvim_exec_lua", lua, {}),
      ("%s: could not dispatch focus notifications to RPC UI client"):format(label))

    local lost = vim.wait(2000, function()
      return focus_lost_events == before_lost + 1 or vim.g.dotfiles_checktime_focus_error ~= nil
    end, 10)
    assert(lost and focus_lost_events == before_lost + 1,
      ("%s: FocusLost not observed; error=%s stderr=%s"):format(
        label, vim.inspect(vim.g.dotfiles_checktime_focus_error), vim.inspect(ui_stderr)))

    local gained = vim.wait(2000, function()
      return focus_gained_events == before_gained + 1 or vim.g.dotfiles_checktime_focus_error ~= nil
    end, 10)
    assert(gained and focus_gained_events == before_gained + 1,
      ("%s: FocusGained not observed; error=%s stderr=%s"):format(
        label, vim.inspect(vim.g.dotfiles_checktime_focus_error), vim.inspect(ui_stderr)))
    last_focus_at = vim.uv.hrtime()
  end
  local function gain_native_focus()
    -- Neovim v0.12.6 throttles native timestamp checks to once per 2000ms.
    local anchor = last_focus_at or test_started_at
    wait_for("native focus timestamp-check throttle", function()
      return vim.uv.hrtime() - anchor >= 2100000000
    end, 2500)
    trigger_native_focus_cycle("native RPC UI focus return")
  end

  -- Create a real RPC UI channel without launching a nested terminal UI.
  -- Neovim's TUI sends these same nvim_ui_set_focus RPC notifications after
  -- parsing terminal focus-reporting sequences. This isolates the server-side
  -- timestamp-check path from PTY/terminal startup behavior.
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

  vim.g.dotfiles_checktime_focus_error = nil
  print("INFO: starting embedded RPC UI process")
  ui_job = vim.fn.jobstart({
    "env", "-u", "NVIM", vim.v.progpath, "--embed", "--headless", "-u", "NONE", "-i", "NONE", "-n",
  }, {
    rpc = true,
    env = { DOTFILES_CHECKTIME_SERVER = server_address },
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
    ("could not start the RPC UI client: %s"):format(vim.inspect(ui_job)))
  print("INFO: RPC UI process started with channel " .. ui_job .. "; sending attach bootstrap")

  -- Do not put the attach script in a child -c command: an embedded Nvim can
  -- wait for a UI before completing startup commands. Send it over the already
  -- open embedded RPC channel so the client can attach to the parent server.
  local attach_script = [[
    local ok, err = xpcall(function()
      local address = vim.env.DOTFILES_CHECKTIME_SERVER
      assert(type(address) == "string" and address ~= "",
        "missing parent Neovim RPC server address")
      local channel = vim.fn.sockconnect("pipe", address, { rpc = true })
      assert(type(channel) == "number" and channel > 0,
        ("could not connect to parent Neovim RPC server %q"):format(tostring(address)))
      _G.dotfiles_checktime_focus_parent_channel = channel
      assert(vim.rpcnotify(channel, "nvim_ui_attach", 80, 24, { rgb = true }),
        "could not send nvim_ui_attach notification to parent")
    end, debug.traceback)
    if not ok then
      io.stderr:write("[checktime-focus-client] " .. tostring(err) .. "\n")
      io.stderr:flush()
      vim.cmd("cquit 1")
    end
  ]]
  assert(vim.rpcnotify(ui_job, "nvim_exec_lua", attach_script, {}),
    "could not send the UI attach bootstrap to the embedded Neovim")

  local attached = vim.wait(5000, function()
    return ui_enter_events == 1 or ui_exit_code ~= nil or vim.g.dotfiles_checktime_focus_error ~= nil
  end, 10)
  assert(attached and ui_enter_events == 1 and ui_exit_code == nil
      and vim.g.dotfiles_checktime_focus_error == nil,
    ("RPC UI did not attach; UIEnter=%d exit_code=%s parent_error=%s stderr=%s"):format(
      ui_enter_events, vim.inspect(ui_exit_code), vim.inspect(vim.g.dotfiles_checktime_focus_error),
      vim.inspect(ui_stderr)))
  print("PASS: attached a separate Neovim RPC UI channel; child stderr: " .. vim.inspect(ui_stderr))

  -- Prime the native focus path while no changed file is loaded.
  trigger_native_focus_cycle("initial native RPC UI focus cycle")
  print("PASS: initial native focus-loss/focus-gain notifications were observed")

    -- Use autoread=false only for this isolated fixture so the native focus
    -- timestamp check reports FileChangedShell and we can assert its result.
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
          focus_gained_events = focus_gained_events,
          focus_lost_events = focus_lost_events,
          buffer_entry_events = buffer_entry_events,
          at = vim.uv.hrtime(),
        }
        -- Reload clean external changes, but never discard unsaved local edits.
        vim.v.fcs_choice = reason == "conflict" and "" or "reload"
      end,
    })

    -- Keep the changed file visible in an inactive focus window while the
    -- user switches between two other windows. Neovim natively checks the
    -- current buffer when entering it; the removed BufWinEnter callback used
    -- :checktime to scan *all* visible buffers. This fixture distinguishes them.
    local focus_win = vim.api.nvim_get_current_win()
    vim.cmd("vsplit")
    local switch_win_a = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    local switch_buf_a = vim.api.nvim_get_current_buf()
    vim.cmd("vsplit")
    local switch_win_b = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    local switch_buf_b = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(switch_buf_a, 0, -1, false, { "cursor movement fixture" })
    vim.api.nvim_win_set_cursor(switch_win_a, { 1, 0 })
    assert(focus_win ~= switch_win_a and focus_win ~= switch_win_b and switch_win_a ~= switch_win_b,
      "window-switch fixture did not create three independent windows")
    assert(vim.api.nvim_win_get_buf(focus_win) == focus_buf,
      "externally modified focus buffer is not isolated in its own window")

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

    -- The initial attach/focus handshake checked an empty editor. Send a
    -- real key after opening the fixture so Neovim is eligible to check again.
    -- First prove an unchanged visible file does not produce a change event.
    send_user_motion(switch_win_a, "l")
    gain_native_focus()
    assert(#changed_events == 0,
      ("an unchanged file produced a focus-change event: %s"):format(vim.inspect(changed_events)))
    print("PASS: native focus checks do not report unchanged files")

    -- A real user has interacted since the last focus check. This resets
    -- Neovim's one-check-per-idle-cycle guard before the external write.
    send_user_motion(switch_win_a, "l")
    local focus_gains_before_switch = focus_gained_events
    local focus_losses_before_switch = focus_lost_events
    write_external(path, {
      "disk version two after focus loss",
      "second line proves content changed",
    })

    -- Change the current buffer repeatedly in the two switch windows and move
    -- between them. The changed file remains visible in focus_win but is never
    -- the current buffer; a global :checktime on BufWinEnter would still find it.
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

    vim.wait(300, function()
      return #changed_events > 0
    end, 10)
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

    -- The native UI focus path calls Neovim's internal check_timestamps().
    gain_native_focus()
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

    local unchanged_event_count = #changed_events
    -- A later external write is detected by the next native focus transition.
    -- Real user input resets Neovim's timestamp guard after the previous check.
    send_user_motion(switch_win_a, "l")
    write_external(path, {
      "disk version three, second external change",
      "third version still has two lines",
    })
    gain_native_focus()
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

    -- A conflict must be reported without replacing unsaved local content.
    send_user_motion(switch_win_a, "l")
    vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, { "local unsaved edit" })
    assert(vim.bo[focus_buf].modified == true, "local fixture edit did not mark the buffer modified")
    write_external(path, { "conflicting external disk version" })
    local before_conflict = #changed_events
    gain_native_focus()
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

    cleanup()
    cleanup_test = nil
end

vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    fail_test(err)
    return
  end

  print("PASS: native checktime focus policy and real UI behavior")
  vim.cmd("qa!")
end, 10)
