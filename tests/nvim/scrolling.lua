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

local function wait_until(label, timeout_ms, predicate)
  local completed = vim.wait(timeout_ms, predicate, 10)
  check(label, true, completed)
end

local function feed_key(key)
  local encoded = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(encoded, "mtx", false)
end

local function prepare_buffer()
  vim.cmd("enew!")
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

local function exercise_motion(key, expected_delta, description)
  prepare_buffer()
  local before = vim.api.nvim_win_get_cursor(0)[1]

  feed_key(key)
  check(description .. " starts the Neoscroll animation", true, animation.scrolling)
  wait_until(description .. " completes its animation", 5000, function()
    return not animation.scrolling
  end)

  local after = vim.api.nvim_win_get_cursor(0)[1]
  check(description .. " moves the cursor by the expected number of lines",
    expected_delta, after - before)
end

local function exercise_mouse_wheel(direction, comparison, description)
  prepare_buffer()
  local before = vim.fn.line("w0")
  local position = vim.api.nvim_win_get_position(0)
  local row = position[1] + math.floor(vim.api.nvim_win_get_height(0) / 2)
  local col = position[2] + 2

  local ok, err = pcall(
    vim.api.nvim_input_mouse,
    "wheel",
    direction,
    "",
    0,
    row,
    col
  )
  check(description .. " sends a real mouse-wheel event", true, ok)
  if not ok then
    error(description .. " mouse input failed: " .. tostring(err))
  end

  wait_until(description .. " changes the visible top line", 2000, function()
    local current = vim.fn.line("w0")
    return comparison == "down" and current > before
      or comparison == "up" and current < before
  end)
  check(description .. " does not start a Neoscroll animation", false, animation.scrolling)
end

local function run()
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
  check("Neoscroll owns the normal page and alignment mappings", {
    "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb",
  }, neoscroll_config.mappings)
  check("all Neoscroll motions use one easing curve", "sine", neoscroll_config.easing)

  animation = require("neoscroll.scroll")
  local window_height = vim.api.nvim_win_get_height(0)
  exercise_motion("<C-d>", 10, "Ctrl-D")
  exercise_motion("<C-u>", -10, "Ctrl-U")
  exercise_motion("<C-f>", window_height, "Ctrl-F")
  exercise_motion("<C-b>", -window_height, "Ctrl-B")
  exercise_motion("<S-Down>", 10, "Shift-Down")
  exercise_motion("<S-Up>", -10, "Shift-Up")

  exercise_mouse_wheel("down", "down", "Mouse wheel down")
  exercise_mouse_wheel("up", "up", "Mouse wheel up")

  print("PASS: one Neoscroll animation engine, six real keyboard motions, and native wheel scrolling")
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write("[scrolling] FAIL: " .. tostring(err) .. "\n")
  io.stderr:flush()
  vim.cmd("cquit 1")
end
