-- Behavioral regression test for the on-demand DAP integration.
-- Run after the normal isolated Neovim startup and locked plugin restore.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local function mason_log()
  -- Mason's logger uses stdpath("log") on Neovim >= 0.8.
  local path = vim.fn.stdpath("log") .. "/mason.log"
  if vim.fn.filereadable(path) ~= 1 then
    return ""
  end
  return table.concat(vim.fn.readfile(path), "\n")
end

-- Keep useful installer lifecycle messages without emitting Mason's
-- per-filesystem-operation TRACE log into the headless CI artifact.
require("mason.settings").set({ log_level = vim.log.levels.INFO })
print("STEP: Mason INFO logging enabled before DAP activation")

-- An unrelated startup must not load any part of the debugger stack or query
-- the Mason registry for DAP adapters.
assert(package.loaded["dap"] == nil, "nvim-dap loaded during idle startup")
assert(package.loaded["dapui"] == nil, "DAP UI loaded during idle startup")
assert(package.loaded["mason-nvim-dap"] == nil, "Mason DAP loaded during idle startup")
assert(package.loaded["nvim-dap-virtual-text"] == nil, "DAP virtual text loaded during idle startup")
assert(
  vim.fn.exists(":DapContinue") == 2 and vim.fn.exists(":DapStepInto") == 2,
  "native DAP commands are not registered as lazy triggers during idle startup"
)

local idle_log = mason_log()
assert(
  not idle_log:find("Cannot find package", 1, true),
  "DAP triggered a Mason registry lookup during idle startup: " .. idle_log
)
pass("DAP stack remains unloaded and does not query Mason during idle startup")

-- Observe Mason's package handles and terminal installation events without
-- patching Neovim's scheduler or filesystem functions.
local registry = require("mason-registry")
local package_names = { "delve", "codelldb", "js-debug-adapter", "debugpy", "dart-debug-adapter" }
local requested_packages = {}
local package_event_chunks = {}
local install_results = {}
registry:on("package:handle", function(pkg, handle)
  if not vim.tbl_contains(package_names, pkg.name) then
    return
  end
  requested_packages[pkg.name] = true
  print(("PACKAGE HANDLE %s"):format(pkg.name))
  handle:on("state:change", function(new_state, old_state)
    print(("PACKAGE STATE %s %s->%s"):format(pkg.name, tostring(old_state), tostring(new_state)))
  end)
  for _, stream in ipairs({ "stdout", "stderr" }) do
    handle:on(stream, function(chunk)
      package_event_chunks[pkg.name] = package_event_chunks[pkg.name] or 0
      package_event_chunks[pkg.name] = package_event_chunks[pkg.name] + 1
      if package_event_chunks[pkg.name] <= 12 then
        print(("PACKAGE %s %s: %s"):format(pkg.name, stream, chunk:gsub("%s+$", ""):sub(1, 240)))
      end
    end)
  end
end)

-- Use Mason's terminal package events as the completion signal. Polling
-- Package:is_installed() repeatedly scans the shared install directory and
-- floods Mason's own TRACE log while installers are active.
registry:on("package:install:success", function(pkg, handle)
  if not vim.tbl_contains(package_names, pkg.name) then
    return
  end
  install_results[pkg.name] = { status = "success", handle = handle }
  print(("PACKAGE INSTALL SUCCESS %s"):format(pkg.name))
end)
registry:on("package:install:failed", function(pkg, handle)
  if not vim.tbl_contains(package_names, pkg.name) then
    return
  end
  local stderr = handle and handle.stdio and handle.stdio.buffers
      and table.concat(handle.stdio.buffers.stderr or {}, "")
    or ""
  install_results[pkg.name] = { status = "failed", handle = handle, error = stderr }
  print(("PACKAGE INSTALL FAILED %s: %s"):format(pkg.name, stderr:gsub("%s+$", ""):sub(1, 400)))
end)

-- Execute the actual remapped key. Neovim's headless input API does not
-- process a queued key during this scripted phase; "x" is required to dispatch
-- the mapping before the script continues. Keep explicit markers around it so
-- a future timeout distinguishes key-dispatch stalls from Mason install waits.
local leader = vim.g.mapleader or "\\"
local keys = vim.api.nvim_replace_termcodes(leader .. "Db", true, false, true)
print("STEP: dispatching the first DAP key")
vim.api.nvim_feedkeys(keys, "xt", false)
print("STEP: first DAP key dispatch returned")

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

-- Ensure that Mason requested every configured adapter before waiting for
-- terminal install events. Do not poll Package:is_installed() here: it scans
-- the shared install root and is not an async installation-completion signal.
local function all_packages_requested()
  for _, name in ipairs(package_names) do
    if not requested_packages[name] then
      return false
    end
  end
  return true
end

wait_for("Mason to request all five configured DAP adapters", 30000, all_packages_requested)
assert(requested_packages["js-debug-adapter"], "Mason did not request js-debug-adapter")
pass("Mason requested all five configured DAP adapters")

local function all_installs_finished()
  for _, name in ipairs(package_names) do
    if not install_results[name] then
      return false
    end
  end
  return true
end

print("WAIT: waiting for Mason package install success/failure events")
local all_finished = vim.wait(240000, all_installs_finished, 100)
if not all_finished then
  local pending = {}
  for _, name in ipairs(package_names) do
    if not install_results[name] then
      table.insert(pending, name)
    end
  end
  error("Timed out waiting for terminal Mason install events: " .. table.concat(pending, ", "))
end

local failed = {}
for _, name in ipairs(package_names) do
  local result = install_results[name]
  if result.status ~= "success" then
    table.insert(failed, ("%s: %s"):format(name, result.error or "installation failed"))
  end
end
assert(#failed == 0, "Mason DAP adapter installations failed: " .. table.concat(failed, "; "))

pass("all configured Mason DAP adapters finished installing")
