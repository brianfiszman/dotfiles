-- Verify that Neotest's explicit Debug Test mapping activates DAP on demand.
-- Run in a fresh Neovim process after the adapter-installation scenario.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

assert(package.loaded["dap"] == nil, "nvim-dap loaded before Neotest was required")
assert(package.loaded["dapui"] == nil, "DAP UI loaded before Neotest was required")
assert(package.loaded["mason-nvim-dap"] == nil, "Mason DAP loaded before Neotest was required")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "DAP virtual text loaded before Neotest was required")

-- Loading Neotest and its adapters must not pull in DAP as an implicit dependency.
local neotest = require("neotest")
assert(package.loaded["dap"] == nil, "loading Neotest initialized nvim-dap")
assert(package.loaded["dapui"] == nil, "loading Neotest initialized DAP UI")
assert(package.loaded["mason-nvim-dap"] == nil, "loading Neotest initialized Mason DAP")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "loading Neotest initialized DAP virtual text")
print("PASS: Neotest loads without initializing the DAP stack")

-- Stub only the test-run entry point so the actual which-key mapping can be
-- dispatched without launching a real test/debug session.
local original_run = neotest.run.run
assert(type(original_run) == "function", "Neotest run entry point is unavailable")
local received_options
neotest.run.run = function(options)
  received_options = options
end

-- which-key intentionally finalizes queued registrations in a scheduled
-- callback. Wait until the mapping exists before simulating a real keypress.
local leader = vim.g.mapleader or "\\"
local lhs = leader .. "td"
wait_for("which-key to register the Debug Test mapping", 30000, function()
  return vim.fn.maparg(lhs, "n") ~= ""
end)
local mapping = vim.fn.maparg(lhs, "n", false, true)
assert(type(mapping) == "table" and mapping.rhs ~= "", "Debug Test mapping has no executable rhs")
print(("MAPPING: Debug Test rhs=%s"):format(mapping.rhs))

local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
print("STEP: dispatching the existing Debug Test mapping")
vim.api.nvim_feedkeys(keys, "xt", false)

wait_for("Debug Test mapping to invoke Neotest", 30000, function()
  return received_options ~= nil
end)
assert(received_options.strategy == "dap", "Debug Test mapping did not request the DAP strategy")
print("PASS: Debug Test mapping invokes Neotest with the DAP strategy")

wait_for("Debug Test mapping to load the full DAP stack", 30000, function()
  return package.loaded["dap"] ~= nil
    and package.loaded["dapui"] ~= nil
    and package.loaded["mason-nvim-dap"] ~= nil
    and package.loaded["nvim-dap-virtual-text"] ~= nil
    and vim.fn.exists(":DapContinue") == 2
end)
print("PASS: Debug Test mapping loads the complete DAP stack")
