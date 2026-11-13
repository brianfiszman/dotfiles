-- Behavioral regression test for the on-demand DAP integration.
-- Run after the normal isolated Neovim startup and locked plugin restore.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local function mason_log()
  local path = vim.fn.stdpath("state") .. "/mason.log"
  if vim.fn.filereadable(path) ~= 1 then
    return ""
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

-- An unrelated startup must not load any part of the debugger stack or query
-- the Mason registry for DAP adapters.
assert(package.loaded["dap"] == nil, "nvim-dap loaded during idle startup")
assert(package.loaded["dapui"] == nil, "DAP UI loaded during idle startup")
assert(package.loaded["mason-nvim-dap"] == nil, "Mason DAP loaded during idle startup")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "DAP virtual text loaded during idle startup")
assert(vim.fn.exists(":DapContinue") == 0, "DAP commands exist during idle startup")

local idle_log = mason_log()
assert(
  not idle_log:find("Cannot find package", 1, true),
  "DAP triggered a Mason registry lookup during idle startup: " .. idle_log
)
pass("DAP stack remains unloaded and does not query Mason during idle startup")

-- Queue the same key a user presses, but let Neovim's event loop process it.
-- Synchronous feedkeys(..., 'x') can hold this test inside input processing
-- while the plugin's async registry/install work is being scheduled.
local leader = vim.g.mapleader or "\\"
local keys = vim.api.nvim_replace_termcodes(leader .. "Db", true, false, true)
vim.api.nvim_feedkeys(keys, "t", false)

wait_for("the first DAP key to load the debugger stack", 30000, function()
  return package.loaded["dap"] ~= nil
    and package.loaded["dapui"] ~= nil
    and package.loaded["mason-nvim-dap"] ~= nil
    and package.loaded["nvim-dap-virtual-text"] ~= nil
    and vim.fn.exists(":DapContinue") == 2
end)
pass("first DAP key loads the full debugger stack and registers :DapContinue")

-- The TypeScript adapters are registered only after Mason's registry refresh.
wait_for("TypeScript DAP adapters to be configured", 30000, function()
  local dap = package.loaded["dap"]
  return dap
    and dap.adapters["pwa-node"] ~= nil
    and dap.adapters["pwa-chrome"] ~= nil
end)
pass("Mason registry refresh configures pwa-node and pwa-chrome")

-- Verify that explicit DAP activation requested the TypeScript adapter. Do not
-- wait for external adapter downloads/builds to finish: those are network- and
-- toolchain-dependent installs, not proof of lazy-loading or adapter wiring.
wait_for("Mason to start the js-debug-adapter install", 30000, function()
  return mason_log():find("Executing installer for Package(name=js-debug-adapter)", 1, true) ~= nil
end)

local active_log = mason_log()
assert(
  not active_log:find("Cannot find package", 1, true),
  "Mason could not resolve a requested DAP adapter: " .. active_log
)
pass("explicit DAP activation requests js-debug-adapter installation")
