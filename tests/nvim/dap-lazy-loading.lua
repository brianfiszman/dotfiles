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

-- Capture Mason diagnostics from the start of explicit activation. The
-- settings module is shared with mason-core.log, which reads log_level for
-- every write, so changing it here covers installer startup and progress.
require("mason.settings").set({ log_level = vim.log.levels.DEBUG })
print("STEP: Mason DEBUG logging enabled before DAP activation")

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

-- Confirm that explicit DAP activation requested the TypeScript adapter and
-- wait for the configured adapters to finish installing. Exiting Neovim while
-- Mason installers are active aborts them, so installation completion is part
-- of this integration test (unlike the lazy-loading assertions above).
wait_for("Mason to start the js-debug-adapter install", 30000, function()
  return mason_log():find("Executing installer for Package(name=js-debug-adapter)", 1, true) ~= nil
end)

local active_log = mason_log()
assert(
  not active_log:find("Cannot find package", 1, true),
  "Mason could not resolve a requested DAP adapter: " .. active_log
)
pass("explicit DAP activation requests js-debug-adapter installation")

local registry = require("mason-registry")
local package_names = { "delve", "codelldb", "js-debug-adapter", "debugpy", "dart-debug-adapter" }
local packages = {}
for _, name in ipairs(package_names) do
  packages[name] = registry.get_package(name)
end

local last_pending = nil
local last_log_line_count = 0
local function emit_new_mason_log_lines()
  local path = vim.fn.stdpath("log") .. "/mason.log"
  if vim.fn.filereadable(path) ~= 1 then
    return
  end

  local lines = vim.fn.readfile(path)
  for index = last_log_line_count + 1, #lines do
    print("MASON: " .. lines[index])
  end
  last_log_line_count = #lines
end

emit_new_mason_log_lines()
print("WAIT: waiting for configured Mason DAP adapters to finish installing")
local packages_installed = vim.wait(240000, function()
  emit_new_mason_log_lines()

  local pending = {}
  for _, name in ipairs(package_names) do
    if not packages[name]:is_installed() then
      table.insert(pending, name)
    end
  end

  local summary = table.concat(pending, ", ")
  if summary ~= last_pending then
    print("WAIT: Mason adapters still installing: " .. (summary ~= "" and summary or "none"))
    last_pending = summary
  end
  return #pending == 0
end, 100)

if not packages_installed then
  local missing = {}
  for _, name in ipairs(package_names) do
    if not packages[name]:is_installed() then
      table.insert(missing, name)
    end
  end
  error("Timed out waiting for DAP adapter installs: " .. table.concat(missing, ", "))
end

pass("all configured Mason DAP adapters finished installing")
