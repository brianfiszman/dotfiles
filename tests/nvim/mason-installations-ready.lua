-- Wait for the real Mason package installations started during normal Lazy
-- setup. The restore process must not :qa! while installers are still active.

local registry = require("mason-registry")
local packages = {
  "tree-sitter-cli",
  "codelldb",
  "dart-debug-adapter",
  "debugpy",
  "delve",
  "js-debug-adapter",
}

local function package_state(name)
  local ok, package = pcall(registry.get_package, name)
  if not ok then
    return nil, "registry package is not available: " .. tostring(package)
  end
  return package
end

local started = vim.wait(120000, function()
  for _, name in ipairs(packages) do
    local package = package_state(name)
    if not package or (not package:is_installed() and not package:is_installing()) then
      return false
    end
  end
  return true
end, 100)
assert(started, "Mason did not start all expected CLI/DAP package installations")

for _, name in ipairs(packages) do
  local package = assert(package_state(name))
  assert(package:is_installed() or package:is_installing(),
    ("Mason package %s was neither installed nor installing"):format(name))
end

local completed = vim.wait(35 * 60 * 1000, function()
  for _, name in ipairs(packages) do
    local package = assert(package_state(name))
    if not package:is_installed() or package:is_installing() then
      return false
    end
  end
  return true
end, 500)

assert(completed, "Mason did not finish all expected CLI/DAP installations before timeout")

for _, name in ipairs(packages) do
  local package = assert(package_state(name))
  assert(package:is_installed() and not package:is_installing(),
    ("Mason package %s did not reach the installed state"):format(name))
  print("PASS: Mason package installed and idle: " .. name)
end
