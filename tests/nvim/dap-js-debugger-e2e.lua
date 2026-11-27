-- Use the real Mason-installed js-debug-adapter to launch Node, stop at a
-- source breakpoint, inspect a local, and resume the process.
local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 100)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local root = vim.fn.getcwd()
local fixture = root .. "/tests/fixtures/dap/node-target.js"
assert(vim.fn.filereadable(fixture) == 1, "Missing Node debug fixture: " .. fixture)
require("lazy").load({ plugins = { "mason-nvim-dap.nvim" } })
local dap = require("dap")
local registry = require("mason-registry")
assert(registry.is_installed("js-debug-adapter"), "Mason js-debug-adapter is not installed")
assert(dap.adapters["pwa-node"] ~= nil, "pwa-node adapter was not configured")
for _, ft in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
  assert(type(dap.configurations[ft]) == "table" and #dap.configurations[ft] > 0,
    "Missing DAP configurations for " .. ft)
end

vim.cmd("cd " .. vim.fn.fnameescape(root))
vim.cmd("edit " .. vim.fn.fnameescape(fixture))
vim.bo.filetype = "javascript"
vim.api.nvim_win_set_cursor(0, { 2, 0 })
dap.set_breakpoint()

local stopped, terminated, stopped_body = false, false, nil
local listener = "dotfiles-js-debugger-e2e"
dap.listeners.after.event_stopped[listener] = function(_, body)
  stopped, stopped_body = true, body
  print(("DAP STOPPED: reason=%s thread=%s"):format(tostring(body.reason), tostring(body.threadId)))
end
dap.listeners.after.event_terminated[listener] = function()
  terminated = true
  print("DAP TERMINATED")
end

print("STEP: launch the actual JavaScript file through pwa-node")
dap.run(vim.deepcopy(dap.configurations.javascript[1]))
local ok, failure = xpcall(function()
  wait_for("Node to stop at the source breakpoint", 90000, function() return stopped end)
  assert(stopped_body and stopped_body.reason == "breakpoint",
    "Unexpected DAP stop: " .. vim.inspect(stopped_body))
  local session = assert(dap.session(), "Stopped DAP event has no active session")
  wait_for("a current DAP stack frame", 15000, function() return session.current_frame ~= nil end)
  local evaluated, eval_error, response = false, nil, nil
  session:evaluate("debugValue", function(err, result)
    eval_error, response, evaluated = err, result, true
  end)
  wait_for("evaluation of local debugValue", 15000, function() return evaluated end)
  assert(not eval_error, "DAP evaluate failed: " .. tostring(eval_error))
  assert(response and response.result == "mason-js-debug-adapter-breakpoint-reached",
    "Wrong DAP evaluate result: " .. vim.inspect(response))
  print("PASS: js-debug-adapter stopped at a source breakpoint and evaluated a local variable")
  dap.continue()
  wait_for("Node termination after Continue", 30000, function() return terminated end)
  print("PASS: Continue resumed the Node process to termination")
end, debug.traceback)
dap.listeners.after.event_stopped[listener] = nil
dap.listeners.after.event_terminated[listener] = nil
if not ok then
  pcall(dap.terminate, { all = true })
  error(failure)
end
