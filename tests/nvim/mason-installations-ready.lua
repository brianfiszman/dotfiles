-- Wait for Mason's configured DAP adapter installations to reach terminal
-- success during locked plugin restoration, before Neovim exits and aborts them.

local registry = require("mason-registry")
local packages = {
  "codelldb",
  "dart-debug-adapter",
  "debugpy",
  "delve",
  "js-debug-adapter",
}
local expected = {}
local results = {}

for _, name in ipairs(packages) do
  expected[name] = true
end

local function finish(name, status, detail)
  if results[name] then
    return
  end
  results[name] = { status = status, detail = detail }
  if status == "success" then
    print(("PASS: Mason package %s installed%s"):format(name, detail and " (" .. detail .. ")" or ""))
  else
    print(("FAIL: Mason package %s: %s"):format(name, detail or "installation failed"))
  end
end

-- Mason 2.x emits this event with an InstallHandle, whose .package field
-- identifies the requested package. The terminal events below carry
-- (Package, receipt/result) and fire only after the install handle is closed.
registry:on("package:install:handle", function(handle)
  local package = handle and handle.package
  if package and expected[package.name] then
    print(("Mason install started: %s"):format(package.name))
  end
end)

registry:on("package:install:success", function(package, receipt)
  if package and expected[package.name] then
    finish(package.name, "success", "completed in this restore process")
  end
end)

registry:on("package:install:failed", function(package, result)
  if package and expected[package.name] then
    finish(package.name, "failed", tostring(result))
  end
end)

-- The restore command may have completed an install before this observer was
-- loaded. A one-time state scan handles those results; the wait predicate below
-- only reads this in-memory table and never polls Mason's filesystem state.
for _, name in ipairs(packages) do
  local package = registry.get_package(name)
  if package:is_installed() then
    finish(name, "success", "already installed")
  else
    local handle = package:get_install_handle():or_else(nil)
    if handle and handle:is_closed() then
      finish(name, "failed", "install handle closed before the readiness observer; package is not installed")
    end
  end
end

local function all_finished()
  for _, name in ipairs(packages) do
    if not results[name] then
      return false
    end
  end
  return true
end

print("WAIT: waiting for terminal Mason success/failure events for all five configured DAP adapters")
local completed = vim.wait(18 * 60 * 1000, all_finished, 100)
if not completed then
  local pending = {}
  for _, name in ipairs(packages) do
    if not results[name] then
      table.insert(pending, name)
    end
  end
  error("Timed out waiting for terminal Mason install events: " .. table.concat(pending, ", "))
end

local failures = {}
for _, name in ipairs(packages) do
  local result = results[name]
  if result.status ~= "success" then
    table.insert(failures, ("%s: %s"):format(name, result.detail or "installation failed"))
  else
    local package = registry.get_package(name)
    assert(package:is_installed(), ("Mason reported %s as installed, but its package directory is missing"):format(name))
    assert(not package:is_installing(), ("Mason package %s is still installing after its terminal success event"):format(name))
  end
end

assert(#failures == 0, "Mason DAP adapter installation failures: " .. table.concat(failures, "; "))
print("PASS: all five configured Mason DAP adapters are installed and idle")
