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
  local rpc_channel
  local focus_gained_events = 0
  local changed_events = {}
  local test_started_at = vim.uv.hrtime()
  local last_focus_at

  local function cleanup()
    if rpc_channel and rpc_channel > 0 then
      pcall(vim.fn.rpcrequest, rpc_channel, "nvim_ui_detach")
      pcall(vim.fn.chanclose, rpc_channel)
    end
    if server_address then
      pcall(vim.fn.serverstop, server_address)
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.fn.delete(path)
  end

  local function gain_native_focus()
    -- Neovim v0.12.6's do_autocmd_focusgained() throttles timestamp checks
    -- to once every 2000ms. Wait past that exact native interval.
    local anchor = last_focus_at or test_started_at
    wait_for("native focus timestamp-check throttle", function()
      return vim.uv.hrtime() - anchor >= 2100000000
    end, 2500)

    local before = focus_gained_events
    local ok, err = pcall(vim.fn.rpcrequest, rpc_channel, "nvim_ui_set_focus", false)
    assert(ok, "could not send native FocusLost through RPC UI: " .. tostring(err))
    ok, err = pcall(vim.fn.rpcrequest, rpc_channel, "nvim_ui_set_focus", true)
    assert(ok, "could not send native FocusGained through RPC UI: " .. tostring(err))
    last_focus_at = vim.uv.hrtime()
    assert(focus_gained_events == before + 1,
      ("native UI focus transition should trigger one FocusGained event: expected %d, got %d"):format(
        before + 1, focus_gained_events))
  end

  local ok, err = xpcall(function()
    -- Attach a second UI to this same Neovim instance. Calling
    -- nvim_ui_set_focus over this RPC channel reaches Neovim's native focus
    -- handler; nvim_exec_autocmds("FocusGained") would not run its internal
    -- check_timestamps() logic.
    server_address = vim.fn.serverstart()
    assert(type(server_address) == "string" and server_address ~= "",
      "serverstart() did not return a Neovim RPC address")
    rpc_channel = vim.fn.sockconnect("pipe", server_address, { rpc = true })
    assert(type(rpc_channel) == "number" and rpc_channel > 0,
      ("sockconnect() failed to connect to Neovim's own RPC server: %s"):format(vim.inspect(rpc_channel)))

    local attached, attach_error = pcall(
      vim.fn.rpcrequest,
      rpc_channel,
      "nvim_ui_attach",
      math.max(vim.o.columns, 80),
      math.max(vim.o.lines, 24),
      { rgb = true, ext_linegrid = true }
    )
    assert(attached, "could not attach the test RPC UI: " .. tostring(attach_error))
    -- Anchor the throttle after attachment/startup side effects, so the first
    -- explicit focus transition is guaranteed to be outside the native window.
    last_focus_at = vim.uv.hrtime()
    print("PASS: attached an RPC UI for native Neovim focus events")

    vim.api.nvim_create_autocmd("FocusGained", {
      group = group,
      callback = function()
        focus_gained_events = focus_gained_events + 1
      end,
    })

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

    local buffer_entry_events = 0
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = group,
      callback = function(event)
        if event.buf == focus_buf or event.buf == other_buf then
          buffer_entry_events = buffer_entry_events + 1
        end
      end,
    })

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
    assert(#changed_events == 0,
      ("buffer/window switching unexpectedly triggered %d file checks: %s"):format(
        #changed_events, vim.inspect(changed_events)))
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
