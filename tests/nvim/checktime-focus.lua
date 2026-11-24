-- Verify Neovim's native focus-return timestamp check without running
-- :checktime on every buffer/window switch.
--
-- nvim_ui_set_focus() is RPC-only. A second RPC UI exercises the same native
-- do_autocmd_focusgained() path used by Neovim's TUI focus escape sequences.

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

local function run()
  local path = vim.fn.tempname() .. ".txt"
  local group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })
  local server_address
  local ui_job
  local ui_enter_events = 0
  local focus_gained_events = 0
  local focus_lost_events = 0
  local changed_events = {}
  local focus_history = {}
  local buffer_entry_events = 0
  local test_started_at = vim.uv.hrtime()
  local last_focus_at


  local function cleanup()
    -- Stop the separate TUI client first so its UI channel detaches cleanly.
    -- It is a real remote UI process, not a same-process rpcrequest to ourselves.
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

  local function gain_native_focus()
    -- Neovim v0.12.6 throttles native timestamp checks to once per 2000ms.
    -- Send focus-reporting escape sequences to a separate PTY-backed remote TUI;
    -- that client parses them and sends nvim_ui_set_focus over its own RPC channel.
    local anchor = last_focus_at or test_started_at
    wait_for("native focus timestamp-check throttle", function()
      return vim.uv.hrtime() - anchor >= 2100000000
    end, 2500)

    local before_lost = focus_lost_events
    local lost_bytes = vim.fn.chansend(ui_job, "\27[O")
    assert(lost_bytes == 3, ("remote TUI accepted %d/3 FocusLost bytes"):format(lost_bytes))
    wait_for("native remote-TUI FocusLost", function()
      return focus_lost_events == before_lost + 1
    end, 2000)

    local before_gained = focus_gained_events
    local gained_bytes = vim.fn.chansend(ui_job, "\27[I")
    assert(gained_bytes == 3, ("remote TUI accepted %d/3 FocusGained bytes"):format(gained_bytes))
    wait_for("native remote-TUI FocusGained", function()
      return focus_gained_events == before_gained + 1
    end, 2000)
    last_focus_at = vim.uv.hrtime()
  end

  local ok, err = xpcall(function()
    -- Start a second Neovim process in a real PTY as a remote UI client.
    -- It receives raw terminal focus-reporting sequences, parses them in the TUI
    -- input layer, and sends nvim_ui_set_focus through its own RPC connection.
    -- This avoids same-process RPC re-entrancy and exercises the actual TUI path.
    server_address = vim.fn.serverstart()
    assert(type(server_address) == "string" and server_address ~= "",
      "serverstart() did not return a Neovim RPC address")

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

    ui_job = vim.fn.jobstart({
      "env", "-u", "NVIM", vim.v.progpath, "--server", server_address, "--remote-ui",
    }, {
      pty = true,
      width = 80,
      height = 24,
      env = { TERM = "xterm-256color" },
    })
    assert(type(ui_job) == "number" and ui_job > 0,
      ("could not start the remote TUI job: %s"):format(vim.inspect(ui_job)))
    wait_for("remote TUI UIEnter", function()
      return ui_enter_events == 1
    end, 5000)
    print("PASS: attached a separate PTY-backed Neovim remote TUI")

    -- Prime the real terminal focus-reporting path while no changed file is
    -- loaded. This consumes the TUI's initial focus transition before the
    -- external-write assertions begin and proves both escape sequences work.
    local initial_lost = focus_lost_events
    local lost_bytes = vim.fn.chansend(ui_job, "\27[O")
    assert(lost_bytes == 3, ("remote TUI accepted %d/3 initial FocusLost bytes"):format(lost_bytes))
    wait_for("initial native remote-TUI FocusLost", function()
      return focus_lost_events == initial_lost + 1
    end, 2000)

    local initial_gained = focus_gained_events
    local gained_bytes = vim.fn.chansend(ui_job, "\27[I")
    assert(gained_bytes == 3, ("remote TUI accepted %d/3 initial FocusGained bytes"):format(gained_bytes))
    wait_for("initial native remote-TUI FocusGained", function()
      return focus_gained_events == initial_gained + 1
    end, 2000)
    last_focus_at = vim.uv.hrtime()
    print("PASS: primed the real PTY focus-loss/focus-gain path before changing the fixture")

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

    local win_a = vim.api.nvim_get_current_win()
    vim.cmd("vsplit")
    local win_b = vim.api.nvim_get_current_win()
    vim.cmd("enew")
    local other_buf = vim.api.nvim_get_current_buf()
    assert(win_a ~= win_b and focus_buf ~= other_buf,
      "window-switch fixture did not create two independent buffers")

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(event)
        if event.buf == focus_buf or event.buf == other_buf then
          buffer_entry_events = buffer_entry_events + 1
        end
      end,
    })

    local focus_gains_before_switch = focus_gained_events
    local focus_losses_before_switch = focus_lost_events
    write_external(path, {
      "disk version two after focus loss",
      "second line proves content changed",
    })

    -- Repeatedly hide and redisplay the focus buffer in one window so each
    -- transition produces a real BufWinEnter. Switch between both windows too;
    -- ordinary window focus changes must not trigger timestamp checks either.
    local spare_buf = vim.api.nvim_create_buf(false, true)
    for _ = 1, 4 do
      vim.api.nvim_win_set_buf(win_a, spare_buf)
      vim.api.nvim_win_set_buf(win_a, focus_buf)
      vim.api.nvim_set_current_win(win_b)
      vim.api.nvim_set_current_win(win_a)
    end
    assert(buffer_entry_events >= 4,
      ("expected at least four real BufWinEnter events for the focus buffer, observed %d"):format(
        buffer_entry_events))

    vim.wait(300, function()
      return #changed_events > 0
    end, 10)
    assert(focus_gained_events == focus_gains_before_switch
        and focus_lost_events == focus_losses_before_switch,
      ("a focus transition occurred during buffer/window switching; gained=%d->%d lost=%d->%d history=%s"):format(
        focus_gains_before_switch, focus_gained_events,
        focus_losses_before_switch, focus_lost_events, vim.inspect(focus_history)))
    assert(#changed_events == 0,
      ("buffer/window switching unexpectedly triggered file checks without a focus transition: events=%s focus_history=%s"):format(
        vim.inspect(changed_events), vim.inspect(focus_history)))
    assert_lines(focus_buf, { "disk version one" },
      "BufWinEnter must not check or reload the externally changed file")
    print("PASS: repeated BufWinEnter events do not run per-window timestamp checks")

    -- The actual RPC focus path calls Neovim's internal check_timestamps().
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
    gain_native_focus()
    assert(#changed_events == unchanged_event_count,
      "native FocusGained raised a duplicate change event for an unchanged file")
    print("PASS: unchanged files do not produce duplicate change prompts on focus")

    -- A later external write is detected by the next native focus transition.
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
  end, debug.traceback)

  if not ok then
    cleanup()
    error(err)
  end
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write("[checktime-focus] " .. tostring(err) .. "\n")
  io.stderr:flush()
  vim.cmd("cquit 1")
end

print("PASS: native checktime focus policy and real UI behavior")
