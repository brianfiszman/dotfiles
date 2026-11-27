-- Exercise the real Debug Test mapping with the real Vitest adapter and
-- Mason-installed js-debug-adapter. This scenario runs Neovim in a PTY/TUI
-- because the locked neotest-vitest adapter requests an integrated terminal.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 100)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local root = vim.fn.getcwd()
local project = root .. "/tests/fixtures/neotest-js/vitest"
local file = project .. "/debug.test.js"
assert(vim.fn.filereadable(file) == 1, "Missing Vitest debug fixture: " .. file)

assert(package.loaded["dap"] == nil, "DAP was already loaded before this scenario")
require("lazy").load({ plugins = { "mason-nvim-dap.nvim" } })
local dap = require("dap")
assert(dap.adapters["pwa-node"] ~= nil, "pwa-node adapter did not load")

vim.cmd("cd " .. vim.fn.fnameescape(project))
vim.cmd("edit " .. vim.fn.fnameescape(file))
vim.bo.filetype = "javascript"

local breakpoint_line
for line, content in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
  if content:find("expect(debugTestMarker)", 1, true) then
    breakpoint_line = line
    break
  end
end
assert(breakpoint_line, "Could not find the debug marker assertion in the fixture")
vim.api.nvim_win_set_cursor(0, { breakpoint_line, 0 })
dap.set_breakpoint()

-- Load Neotest through Lazy, then exercise its actual Debug Test mapping.
require("lazy").load({ plugins = { "neotest" } })
local neotest = require("neotest")
if vim.v.vim_did_enter == 0 then
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end
local lhs = (vim.g.mapleader or "\\") .. "td"
wait_for("the configured Debug Test mapping", 30000, function()
  return vim.fn.maparg(lhs, "n") ~= ""
end)

local stopped, terminated, stopped_body = false, false, nil
local listener = "dotfiles-neotest-dap-e2e"
dap.listeners.after.event_stopped[listener] = function(_, body)
  stopped, stopped_body = true, body
  print(("NEOTEST DAP STOPPED: reason=%s"):format(tostring(body.reason)))
end
dap.listeners.after.event_terminated[listener] = function()
  terminated = true
  print("NEOTEST DAP TERMINATED")
end

print("STEP: dispatching the actual <leader>td mapping")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "xt", false)

local ok, failure = xpcall(function()
  wait_for("the test process to stop at the source breakpoint", 90000, function()
    return stopped
  end)
  assert(stopped_body and stopped_body.reason == "breakpoint",
    "Debug Test stopped unexpectedly: " .. vim.inspect(stopped_body))

  local session = assert(dap.session(), "Debug Test stop has no active DAP session")
  wait_for("the test's stopped stack frame", 15000, function()
    return session.current_frame ~= nil
  end)
  local evaluated, eval_error, response = false, nil, nil
  session:evaluate("debugTestMarker", function(err, result)
    eval_error, response, evaluated = err, result, true
  end)
  wait_for("evaluation of debugTestMarker", 15000, function() return evaluated end)
  assert(not eval_error, "Debug Test evaluation failed: " .. tostring(eval_error))
  assert(response and response.result == "neotest-vitest-breakpoint-reached",
    "Debug Test evaluated an unexpected value: " .. vim.inspect(response))
  print("PASS: <leader>td reached a real Vitest source breakpoint and evaluated local state")

  dap.continue()
  wait_for("Neotest to receive the completed Vitest result", 60000, function()
    local counts = neotest.state.status_counts("neotest-vitest")
    return terminated and counts and counts.total == 1 and counts.running == 0
      and counts.passed == 1 and counts.failed == 0
  end)
  print("PASS: resuming the debugged test produced a real passing Neotest result")
end, debug.traceback)

dap.listeners.after.event_stopped[listener] = nil
dap.listeners.after.event_terminated[listener] = nil
if not ok then
  pcall(dap.terminate, { all = true })
  error(failure)
end
assert(package.loaded["dap"] ~= nil and package.loaded["dapui"] ~= nil,
  "Debug Test did not load the complete DAP stack")
