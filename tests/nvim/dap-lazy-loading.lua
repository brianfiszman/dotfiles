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
require("mason.settings").set({ log_level = vim.log.levels.TRACE })
print("STEP: Mason TRACE logging enabled before DAP activation")

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

-- Instrument the exact boundary where Mason's installer setup currently stalls.
-- This is test-process-only: record scheduled callback execution, mkdir return
-- values, package handle states, and installer stdout/stderr.
local original_schedule = vim.schedule
local scheduled_count = 0
vim.schedule = function(callback)
  scheduled_count = scheduled_count + 1
  local id = scheduled_count
  if id <= 60 then
    print(("SCHEDULE QUEUED %d"):format(id))
  end
  return original_schedule(function()
    if id <= 60 then
      print(("SCHEDULE BEGIN %d"):format(id))
    end
    callback()
    if id <= 60 then
      print(("SCHEDULE END %d"):format(id))
    end
  end)
end

local original_mkdir = vim.fn.mkdir
vim.fn.mkdir = function(path, flags)
  local mason_path = path:find("/mason/", 1, true) ~= nil
  if mason_path then
    print(("MKDIR ENTER path=%s flags=%s"):format(path, tostring(flags)))
  end
  local ok, result = pcall(original_mkdir, path, flags)
  if mason_path then
    print(("MKDIR RETURN path=%s ok=%s result=%s"):format(path, tostring(ok), tostring(result)))
  end
  if not ok then
    error(result, 0)
  end
  return result
end

local registry = require("mason-registry")
local package_names = { "delve", "codelldb", "js-debug-adapter", "debugpy", "dart-debug-adapter" }
local package_event_chunks = {}
registry:on("package:handle", function(pkg, handle)
  if not vim.tbl_contains(package_names, pkg.name) then
    return
  end
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
registry:on("package:install:success", function(pkg)
  if vim.tbl_contains(package_names, pkg.name) then
    print(("PACKAGE INSTALL SUCCESS %s"):format(pkg.name))
  end
end)
registry:on("package:install:failed", function(pkg)
  if vim.tbl_contains(package_names, pkg.name) then
    print(("PACKAGE INSTALL FAILED %s"):format(pkg.name))
  end
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
  local interesting = {
    "Creating new handle for",
    "Changing InstallHandle",
    "Executing installer for",
    "Attempting to lock package",
    "Wrote lockfile",
    "Compiling installer.",
    "Parsing spec",
    "Parsed purl.",
    "Found provider for purl.",
    "Parsed source for purl.",
    "fs: dir_exists",
    "fs: fstat",
    "fs: mkdirp",
    "fs: mkdirp failed",
    "Spawning cmd=",
    "Job pid=",
    "Installation succeeded",
    "Installation failed",
    "Failed to spawn process",
    "Unexpected error",
  }

  for index = last_log_line_count + 1, #lines do
    local line = lines[index]
    for _, marker in ipairs(interesting) do
      if line:find(marker, 1, true) then
        print("MASON: " .. line)
        break
      end
    end
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
