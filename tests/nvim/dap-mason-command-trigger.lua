-- Verify that Mason's :DapInstall entry point lazy-loads the debugger stack.
-- Invoking it with no arguments is intentionally non-destructive.

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 50)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

local package_names = { "delve", "codelldb", "js-debug-adapter", "debugpy", "dart-debug-adapter" }
local requested_packages = {}
local install_results = {}
local package_output_chunks = {}
local registry = require("mason-registry")

for _, name in ipairs(package_names) do
  if registry.is_installed(name) then
    requested_packages[name] = true
    install_results[name] = { status = "success", existing = true }
  end
end

registry:on("package:handle", function(pkg, handle)
  if not vim.tbl_contains(package_names, pkg.name) then
    return
  end
  requested_packages[pkg.name] = true
  handle:on("stdout", function(chunk)
    package_output_chunks[pkg.name] = package_output_chunks[pkg.name] or 0
    package_output_chunks[pkg.name] = package_output_chunks[pkg.name] + 1
    if package_output_chunks[pkg.name] <= 4 then
      print(("PACKAGE %s stdout: %s"):format(pkg.name, chunk:gsub("%s+$", ""):sub(1, 200)))
    end
  end)
  handle:on("stderr", function(chunk)
    package_output_chunks[pkg.name] = package_output_chunks[pkg.name] or 0
    package_output_chunks[pkg.name] = package_output_chunks[pkg.name] + 1
    if package_output_chunks[pkg.name] <= 4 then
      print(("PACKAGE %s stderr: %s"):format(pkg.name, chunk:gsub("%s+$", ""):sub(1, 200)))
    end
  end)
end)
registry:on("package:install:success", function(pkg, handle)
  if vim.tbl_contains(package_names, pkg.name) then
    install_results[pkg.name] = { status = "success", handle = handle }
    print(("PACKAGE INSTALL SUCCESS %s"):format(pkg.name))
  end
end)
registry:on("package:install:failed", function(pkg, handle)
  if vim.tbl_contains(package_names, pkg.name) then
    local stderr = handle and handle.stdio and handle.stdio.buffers
        and table.concat(handle.stdio.buffers.stderr or {}, "")
      or ""
    install_results[pkg.name] = { status = "failed", handle = handle, error = stderr }
    print(("PACKAGE INSTALL FAILED %s: %s"):format(pkg.name, stderr:gsub("%s+$", ""):sub(1, 400)))
  end
end)

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

assert(registry.has_package("debugpy"), "Mason registry was not ready when the first DapInstall command was replayed")

wait_for("Mason DAP command to load the complete stack and register its API", 30000, function()
  return package.loaded["dap"] ~= nil
    and package.loaded["dapui"] ~= nil
    and package.loaded["mason-nvim-dap"] ~= nil
    and package.loaded["nvim-dap-virtual-text"] ~= nil
    and vim.fn.exists(":DapContinue") == 2
    and vim.fn.exists(":DapUninstall") == 2
end)
print("PASS: :DapInstall lazy-loads the full DAP stack and registers Mason commands")

local function all_packages_requested()
  for _, name in ipairs(package_names) do
    if not requested_packages[name] then
      return false
    end
  end
  return true
end
wait_for("Mason to request all five adapters from a clean registry", 30000, all_packages_requested)

local function all_installs_finished()
  for _, name in ipairs(package_names) do
    if not install_results[name] then
      return false
    end
  end
  return true
end
print("WAIT: waiting for Mason adapter installations after the first DapInstall action")
local finished = vim.wait(240000, all_installs_finished, 100)
assert(finished, "Timed out waiting for Mason adapters after :DapInstall")
local failures = {}
for _, name in ipairs(package_names) do
  if install_results[name].status ~= "success" then
    table.insert(failures, (name .. ": " .. (install_results[name].error or "failed")))
  end
end
assert(#failures == 0, "Mason adapter installation failures: " .. table.concat(failures, "; "))
print("PASS: :DapInstall first-use also installs all configured adapters")
