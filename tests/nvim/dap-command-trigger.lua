-- Verify that a native nvim-dap user command is a lazy-loading trigger.
-- Run in a fresh Neovim process after the adapter-installation scenario.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local command_names = {
  "DapSetLogLevel",
  "DapShowLog",
  "DapContinue",
  "DapToggleBreakpoint",
  "DapClearBreakpoints",
  "DapToggleRepl",
  "DapStepOver",
  "DapStepInto",
  "DapStepOut",
  "DapPause",
  "DapTerminate",
  "DapDisconnect",
  "DapRestartFrame",
  "DapNew",
  "DapEval",
}

assert(package.loaded["dap"] == nil, "nvim-dap loaded before a native DAP command was invoked")
assert(package.loaded["dapui"] == nil, "DAP UI loaded before a native DAP command was invoked")
assert(package.loaded["mason-nvim-dap"] == nil, "Mason DAP loaded before a native DAP command was invoked")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "DAP virtual text loaded before a native DAP command was invoked")

for _, name in ipairs(command_names) do
  assert(vim.fn.exists(":" .. name) == 2, ("native DAP command is not registered as a lazy trigger: %s"):format(name))
end
print("PASS: all 15 native DAP commands are registered as lazy triggers")

-- DapSetLogLevel is non-destructive and has a simple required argument, so it
-- exercises the native command loader without opening a UI or starting a session.
print("STEP: invoking :DapSetLogLevel INFO as the first DAP action")
vim.cmd("DapSetLogLevel INFO")

wait_for("native DAP command to load the full debugger stack", 30000, function()
  return package.loaded["dap"] ~= nil
    and package.loaded["dapui"] ~= nil
    and package.loaded["mason-nvim-dap"] ~= nil
    and package.loaded["nvim-dap-virtual-text"] ~= nil
    and vim.fn.exists(":DapContinue") == 2
end)
print("PASS: native DAP command loads the complete DAP stack")
