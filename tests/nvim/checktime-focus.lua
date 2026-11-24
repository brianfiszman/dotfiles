-- Verify native autoread watchers and the FocusGained fallback without
-- running :checktime on every buffer/window switch.
--
-- The focus fallback fixture disables autoread only for one buffer so the
-- test can distinguish BufWinEnter from FocusGained deterministically. The
-- default autoread path is exercised separately with the real filesystem watcher.

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
  local watcher_path = vim.fn.tempname() .. ".txt"
  local focus_path = vim.fn.tempname() .. ".txt"
  local event_group = vim.api.nvim_create_augroup("DotfilesChecktimeFocusTest", { clear = true })

  -- Normal Neovim behavior: autoread is on by default and uses the OS file
  -- watcher to reload a clean buffer as soon as an external write is observed.
  write_external(watcher_path, { "watcher version one" })
  vim.cmd("edit " .. vim.fn.fnameescape(watcher_path))
  local watcher_buf = vim.api.nvim_get_current_buf()
  local global_autoread = vim.go.autoread
  local buffer_autoread = vim.bo[watcher_buf].autoread
  print(("INFO: autoread global=%s buffer-local=%s"):format(
    tostring(global_autoread), tostring(buffer_autoread)))
  assert(global_autoread == true,
    ("configured Neovim should retain the default global autoread behavior (got %s)"):format(
      tostring(global_autoread)))
  -- A global-local option may have a distinct local value. Make the fixture
  -- explicit so the native watcher path is tested independently of that value.
  vim.bo[watcher_buf].autoread = global_autoread
  assert(vim.bo[watcher_buf].autoread == true,
    "watcher fixture did not enable buffer-local autoread")
  write_external(watcher_path, { "watcher version two from outside Neovim" })
  wait_for("autoread filesystem watcher to reload a clean buffer", function()
    return buffer_lines(watcher_buf)[1] == "watcher version two from outside Neovim"
  end, 5000)
  print("PASS: autoread reloads external changes through the native filesystem watcher")

  -- Isolate the focus fallback from native watchers so repeated BufWinEnter
  -- events can be distinguished from the single intentional FocusGained check.
  write_external(focus_path, { "focus version one" })
  vim.cmd("edit " .. vim.fn.fnameescape(focus_path))
  local focus_buf = vim.api.nvim_get_current_buf()
  vim.bo[focus_buf].autoread = false
  assert(vim.bo[focus_buf].autoread == false,
    "focus fallback fixture failed to disable autoread for its buffer")

  local changed_events = {}
  vim.api.nvim_create_autocmd("FileChangedShell", {
    group = event_group,
    callback = function(event)
      local reason = vim.v.fcs_reason
      changed_events[#changed_events + 1] = {
        buffer = event.buf,
        file = event.file,
        reason = reason,
      }

      -- The test owns the decision explicitly: reload clean external changes,
      -- but leave an unsaved local buffer untouched on conflict.
      if reason == "conflict" then
        vim.v.fcs_choice = ""
      else
        vim.v.fcs_choice = "reload"
      end
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
    group = event_group,
    callback = function(event)
      if event.buf == focus_buf or event.buf == other_buf then
        buffer_entry_events = buffer_entry_events + 1
      end
    end,
  })

  write_external(focus_path, {
    "focus version two, changed while Neovim was not focused",
    "second line proves content changed",
  })

  -- Repeatedly display each buffer in the second window. This exercises real
  -- BufWinEnter events while FocusGained is deliberately not dispatched.
  vim.api.nvim_set_current_win(win_b)
  for _ = 1, 4 do
    vim.api.nvim_win_set_buf(win_b, focus_buf)
    vim.api.nvim_win_set_buf(win_b, other_buf)
  end
  assert(buffer_entry_events >= 8,
    ("expected repeated real BufWinEnter events, observed %d"):format(buffer_entry_events))

  -- checktime invoked from the removed BufWinEnter autocmd would be deferred
  -- until this process returns to the event loop and would fire FileChangedShell.
  vim.wait(300, function()
    return #changed_events > 0
  end, 10)
  assert(#changed_events == 0,
    ("buffer/window switching unexpectedly triggered %d external-file checks: %s"):format(
      #changed_events, vim.inspect(changed_events)))
  assert_lines(focus_buf, { "focus version one" },
    "BufWinEnter must not reload or check the externally changed file")
  print("PASS: repeated buffer/window entries do not run per-window external-file checks")

  -- Returning focus invokes one checktime fallback and catches the real change.
  vim.api.nvim_exec_autocmds("FocusGained", { modeline = false })
  wait_for("FocusGained checktime to detect the external change", function()
    return #changed_events == 1 and buffer_lines(focus_buf)[1]
      == "focus version two, changed while Neovim was not focused"
  end, 3000)
  assert(changed_events[1].reason == "changed",
    "FocusGained should report a clean external change, got " .. tostring(changed_events[1].reason))
  assert_lines(focus_buf, {
    "focus version two, changed while Neovim was not focused",
    "second line proves content changed",
  }, "FocusGained reload")
  print("PASS: FocusGained detects and reloads an external change exactly once")

  -- Unchanged files must not produce a duplicate FileChangedShell event.
  local unchanged_event_count = #changed_events
  vim.api.nvim_exec_autocmds("FocusGained", { modeline = false })
  vim.wait(250, function()
    return #changed_events > unchanged_event_count
  end, 10)
  assert(#changed_events == unchanged_event_count,
    "FocusGained rechecked an unchanged file and raised a duplicate change event")
  print("PASS: unchanged files do not produce duplicate change prompts on focus")

  -- A later external write is still found on the next focus return.
  write_external(focus_path, {
    "focus version three, second external change",
    "third version still has two lines",
  })
  vim.api.nvim_exec_autocmds("FocusGained", { modeline = false })
  wait_for("second FocusGained checktime to detect a later external change", function()
    return #changed_events == unchanged_event_count + 1
      and buffer_lines(focus_buf)[1] == "focus version three, second external change"
  end, 3000)
  assert(changed_events[#changed_events].reason == "changed",
    "second clean external change should be reported as changed")
  print("PASS: a later external change is detected on the next focus return")

  -- Never silently replace unsaved local edits when the disk version changes.
  vim.api.nvim_buf_set_lines(focus_buf, 0, -1, false, { "local unsaved edit" })
  assert(vim.bo[focus_buf].modified == true, "local fixture edit did not mark the buffer modified")
  write_external(focus_path, { "conflicting external disk version" })
  local before_conflict = #changed_events
  vim.api.nvim_exec_autocmds("FocusGained", { modeline = false })
  wait_for("modified-buffer conflict to be reported", function()
    return #changed_events == before_conflict + 1
  end, 3000)
  assert(changed_events[#changed_events].reason == "conflict",
    "modified buffer should report a FileChangedShell conflict")
  assert_lines(focus_buf, { "local unsaved edit" },
    "external changes must not overwrite local unsaved edits")
  assert(vim.bo[focus_buf].modified == true,
    "external conflict unexpectedly cleared the modified flag")
  print("PASS: FocusGained preserves unsaved local edits on external conflict")

  vim.api.nvim_del_augroup_by_id(event_group)
  vim.fn.delete(watcher_path)
  vim.fn.delete(focus_path)
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write("[checktime-focus] " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
end

print("PASS: checktime focus policy and native autoread behavior")
