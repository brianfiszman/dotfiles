-- Exercise the actual scroll mappings and native mouse wheel with the real config.
-- Every motion uses real input; checking a mapping or loaded module alone is not enough.

local function check(label, expected, actual)
  if not vim.deep_equal(expected, actual) then
    error(("%s: expected %s, got %s"):format(
      label,
      vim.inspect(expected),
      vim.inspect(actual)
    ))
  end
  print("PASS: " .. label)
end

local animation
local animation_starts = 0
local test_finished = false

local function fail(err)
  if test_finished then
    return
  end
  test_finished = true
  io.stderr:write("[scrolling] FAIL: " .. debug.traceback(tostring(err), 2) .. "\n")
  io.stderr:flush()
  vim.cmd("cquit 1")
end

local function feed_key(key)
  local encoded = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(encoded, "mtx", false)
end

local function prepare_buffer()
  -- Reuse the current scratch buffer. Repeated :enew! calls retrigger
  -- unrelated BufEnter/FileExplorer compatibility autocmds in the PTY.
  local lines = {}
  for line = 1, 1600 do
    lines[line] = ("scroll-fixture-%04d"):format(line)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modified = false
  vim.bo.filetype = ""
  vim.wo.wrap = false
  vim.wo.foldenable = false
  vim.wo.foldmethod = "manual"
  vim.wo.scrolloff = 0
  vim.wo.scroll = 10
  vim.api.nvim_win_set_cursor(0, { 800, 0 })
  vim.cmd("normal! zz")
end

local function wait_for_animation(description)
  local completed = vim.wait(5000, function()
    return not animation.scrolling
  end, 10)
  check(description .. " completes its animation", true, completed)
end

local function wait_for_idle_before_mouse(description)
  -- A prior keyboard animation must have fully torn down before native wheel
  -- input is tested. Checking the live flag only after the wheel event can
  -- mistake a still-running previous animation for a new mouse animation.
  local idle = vim.wait(5000, function()
    return not animation.scrolling
  end, 10)
  check(description .. " starts after the previous animation has finished", true, idle)
end

local function wait_for_animation_quiet(description)
  -- Neoscroll can finish its visible animation one event-loop turn before a
  -- delayed callback from the previous key motion runs. Require a quiet
  -- window with both the animation flag and hook counter stable before
  -- attributing any later hook to native mouse-wheel input.
  local starts = animation_starts
  local quiet_since = vim.uv.hrtime()
  local quiet = vim.wait(3000, function()
    if animation.scrolling or animation_starts ~= starts then
      starts = animation_starts
      quiet_since = vim.uv.hrtime()
      return false
    end
    return vim.uv.hrtime() - quiet_since >= 250000000
  end, 10)
  check(description .. " reaches a stable idle state before mouse input", true, quiet)
end

local function exercise_motion(key, expected_delta, description)
  prepare_buffer()
  local before = vim.api.nvim_win_get_cursor(0)[1]

  local starts_before = animation_starts
  feed_key(key)
  local started = animation_starts > starts_before
    or vim.wait(100, function() return animation_starts > starts_before end, 1)
  check(description .. " invokes Neoscroll's animation hook", true, started)
  check(description .. " starts exactly one animation", 1, animation_starts - starts_before)
  wait_for_animation(description)

  local after = vim.api.nvim_win_get_cursor(0)[1]
  check(description .. " moves the cursor by the expected number of lines",
    expected_delta, after - before)
end

local function exercise_mouse_wheel(direction, description, next_step)
  prepare_buffer()
  wait_for_idle_before_mouse(description)
  wait_for_animation_quiet(description)
  -- The synthetic PTY may leave a hit-enter prompt after querying terminal
  -- background color. Dismiss it before queuing non-blocking mouse input; then
  -- restore the fixture position so the prompt cannot affect the assertion.
  feed_key("<CR>")
  check(description .. " leaves Neovim in Normal mode before mouse input", "n",
    vim.fn.mode():sub(1, 1))
  vim.cmd("messages clear")
  vim.api.nvim_win_set_cursor(0, { 800, 0 })
  vim.cmd("normal! zz")
  local winid = vim.api.nvim_get_current_win()
  local before = vim.fn.line("w0")
  local position = vim.api.nvim_win_get_position(winid)
  local screen_position = vim.fn.win_screenpos(winid)
  local info = vim.fn.getwininfo(winid)[1]
  local expected_row = screen_position[1] - 1
  local expected_col = screen_position[2] - 1
  check(description .. " window position APIs agree", true,
    position[1] == expected_row and position[2] == expected_col)

  -- nvim_input_mouse(grid=0) expects screen-global, zero-based coordinates.
  -- Aim in the middle of the actual text area, not the number/sign gutter.
  local row = expected_row + math.floor(info.height / 2)
  -- Keep the pointer near the left edge of the text area. Mason/Noice can
  -- display floating notifications over the middle of the editor grid.
  local col = expected_col + (info.textoff or 0) + 2
  local starts_before_mouse = animation_starts
  print(("INFO: %s before_top=%d winid=%d winrow=%d wincol=%d width=%d height=%d textoff=%d position=%d,%d screenpos=%d,%d mouse=%d,%d animation_starts=%d"):format(
    description, before, winid, info.winrow, info.wincol, info.width, info.height,
    info.textoff or 0, position[1], position[2],
    screen_position[1], screen_position[2], row, col, starts_before_mouse
  ))

  -- nvim_input_mouse() is non-blocking. Return to Neovim's main loop after
  -- queueing it so the input event is consumed before the assertion runs.
  vim.defer_fn(function()
    if test_finished then
      return
    end

    -- The API action already names the intended wheel direction. Keep it
    -- aligned with Neovim's own functional UI tests instead of reversing it.
    local sent, send_error = pcall(
      vim.api.nvim_input_mouse,
      "wheel",
      direction,
      "",
      0,
      row,
      col
    )
    if not sent then
      fail(description .. " could not queue a real mouse-wheel event: " .. tostring(send_error))
      return
    end

    local deadline = vim.uv.hrtime() + 1000000000

    local function verify_wheel_input()
      if test_finished then
        return
      end

      local after = vim.fn.line("w0")
      local moved = direction == "down" and after > before
        or direction == "up" and after < before

      -- The mouse API only queues input. Keep returning to Neovim's TUI loop
      -- between polls so it can consume the event before checking the screen.
      if not moved and vim.uv.hrtime() < deadline then
        vim.defer_fn(verify_wheel_input, 25)
        return
      end

      print(("INFO: %s after_top=%d cursor=%d"):format(
        description, after, vim.api.nvim_win_get_cursor(winid)[1]
      ))

      local ok, err = xpcall(function()
        check(("%s changes the viewport in the expected direction (topline %d -> %d)"):format(
          description, before, after
        ), true, moved)
        check(description .. " does not invoke Neoscroll's animation hook",
          starts_before_mouse, animation_starts)
        check(description .. " does not leave a Neoscroll animation active",
          false, animation.scrolling)
      end, debug.traceback)

      if not ok then
        fail(err)
        return
      end

      next_step()
    end

    -- Let this callback return to the real TUI event loop after enqueueing the
    -- wheel event. The next poll runs only after Neovim has had time to read it.
    vim.defer_fn(verify_wheel_input, 25)
  end, 0)
end

local function run()
  check("native mouse-wheel test has an attached Neovim UI", true,
    #vim.api.nvim_list_uis() > 0)

  local lazy_config = require("lazy.core.config")
  check("Neoscroll is the only declared scroll-animation plugin", true,
    lazy_config.plugins["neoscroll.nvim"] ~= nil
      and lazy_config.plugins["mini.animate"] == nil
      and lazy_config.plugins["comfortable-motion.vim"] == nil)
  check("Neoscroll is active in the real startup", true, package.loaded["neoscroll"] ~= nil)
  check("mini.animate is absent from the isolated plugin install", 0,
    vim.fn.isdirectory(vim.fn.stdpath("data") .. "/lazy/mini.animate"))
  check("comfortable-motion is absent from the isolated plugin install", 0,
    vim.fn.isdirectory(vim.fn.stdpath("data") .. "/lazy/comfortable-motion.vim"))
  check("comfortable-motion's obsolete global is gone", nil,
    vim.g.comfortable_motion_no_default_key_mappings)

  check("native mouse support remains enabled", "a", vim.o.mouse)
  check("scroll-wheel down has no plugin mapping", "", vim.fn.maparg("<ScrollWheelDown>", "n"))
  check("scroll-wheel up has no plugin mapping", "", vim.fn.maparg("<ScrollWheelUp>", "n"))

  local neoscroll_config = require("neoscroll.config").opts
  check("Neoscroll owns the normal line and alignment mappings", {
    "<C-u>", "<C-d>", "<C-b>", "<C-y>", "<C-e>", "zt", "zz", "zb",
  }, neoscroll_config.mappings)
  check("PageDown and PageUp are dedicated smooth page mappings", true,
    vim.fn.maparg("<PageDown>", "n", false, true).desc == "Smooth page down"
      and vim.fn.maparg("<PageUp>", "n", false, true).desc == "Smooth page up")
  check("Ctrl-F remains assigned to formatting", "<cmd>Format<cr>",
    vim.fn.maparg("<C-f>", "n", false, true).rhs)
  check("all Neoscroll motions use one easing curve", "sine", neoscroll_config.easing)

  animation = require("neoscroll.scroll")
  local neoscroll_options = require("neoscroll.config").opts
  local previous_pre_hook = neoscroll_options.pre_hook
  neoscroll_options.pre_hook = function(info)
    animation_starts = animation_starts + 1
    if previous_pre_hook then
      previous_pre_hook(info)
    end
  end

  local window_height = vim.api.nvim_win_get_height(0)
  exercise_motion("<C-d>", 10, "Ctrl-D")
  exercise_motion("<C-u>", -10, "Ctrl-U")
  exercise_motion("<PageDown>", window_height, "PageDown")
  exercise_motion("<PageUp>", -window_height, "PageUp")
  exercise_motion("<C-b>", -window_height, "Ctrl-B")
  exercise_motion("<S-Down>", 10, "Shift-Down")
  exercise_motion("<S-Up>", -10, "Shift-Up")

  exercise_mouse_wheel("down", "Mouse wheel down", function()
    exercise_mouse_wheel("up", "Mouse wheel up", function()
      test_finished = true
      print("PASS: one Neoscroll animation engine, eight real keyboard motions, preserved Ctrl-F formatting, and native wheel scrolling")
      vim.cmd("qa!")
    end)
  end)
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  fail(err)
  return
end

-- Do not block inside vim.wait() here. nvim_input_mouse() enqueues input for
-- Neovim's main input loop; vim.wait() runs libuv callbacks but does not make
-- the editor consume that queued input. Returning from this startup script
-- lets the real TUI loop process the wheel event before the verification
-- timer fires.
vim.defer_fn(function()
  if not test_finished then
    fail("scroll integration test did not complete both native wheel checks")
  end
end, 5000)
