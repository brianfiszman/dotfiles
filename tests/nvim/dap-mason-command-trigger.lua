-- Verify that Mason's :DapInstall entry point lazy-loads the debugger stack.
-- Invoking it with no arguments is intentionally non-destructive.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

assert(package.loaded["dap"] == nil, "nvim-dap loaded before DapInstall was invoked")
assert(package.loaded["dapui"] == nil, "DAP UI loaded before DapInstall was invoked")
assert(package.loaded["mason-nvim-dap"] == nil, "Mason DAP loaded before DapInstall was invoked")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "DAP virtual text loaded before DapInstall was invoked")
assert(vim.fn.exists(":DapInstall") == 2, ":DapInstall is not registered as a lazy trigger")
assert(vim.fn.exists(":DapUninstall") == 2, ":DapUninstall is not registered as a lazy trigger")
print("PASS: Mason DAP commands are available as lazy placeholders while DAP is unloaded")

-- Empty arguments parse to no packages, so this does not open the Mason UI or
-- install/uninstall anything. It exercises the actual user-facing lazy command.
print("STEP: invoking :DapInstall with no adapter arguments")
vim.cmd("DapInstall")

wait_for("Mason DAP command to load the complete stack", 30000, function()
  return package.loaded["dap"] ~= nil
    and package.loaded["dapui"] ~= nil
    and package.loaded["mason-nvim-dap"] ~= nil
    and package.loaded["nvim-dap-virtual-text"] ~= nil
    and vim.fn.exists(":DapContinue") == 2
    and vim.fn.exists(":DapUninstall") == 2
end)
print("PASS: :DapInstall lazy-loads the full DAP stack and registers Mason commands")
