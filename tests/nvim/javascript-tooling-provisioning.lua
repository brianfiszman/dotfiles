-- Verify real Mason provisioning for the common JavaScript/TypeScript stack.
-- Run after ordinary startup in the isolated headless workspace.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  local ready = vim.wait(timeout_ms, predicate, 100)
  assert(ready, ("Timed out waiting for %s"):format(description))
end

-- TypeScript and ESLint servers are owned by Mason-LSPConfig and are
-- asserted in its native-LSP setup test. This installer owns the formatter
-- and DAP adapter; those packages must be present after normal startup.
local expected = {
  { package = "prettier", executable = "prettier" },
  { package = "js-debug-adapter", executable = "js-debug-adapter" },
}

-- Assert the actual resolved Lazy spec: these must be startup-provisioned,
-- not merely left behind by an earlier interactive Mason install.
local lazy_config = require("lazy.core.config")
local installer_plugin = lazy_config.plugins["mason-tool-installer.nvim"]
assert(type(installer_plugin) == "table", "Mason Tool Installer plugin spec is missing")
local tool_options = installer_plugin.opts or {}
local ensured_tools = tool_options.ensure_installed or {}
for _, package in ipairs({ "prettier", "js-debug-adapter" }) do
  assert(
    vim.tbl_contains(ensured_tools, package),
    ("Mason Tool Installer does not ensure %s on startup"):format(package)
  )
end

local lsp = require("lsp.config")
for _, server in ipairs({ "ts_ls", "eslint" }) do
  assert(
    vim.tbl_contains(lsp.mason_options.ensure_installed, server),
    ("Mason-LSPConfig does not ensure %s"):format(server)
  )
end
pass("Mason Tool Installer and Mason-LSPConfig declare their JS/TS packages")

-- The normal-startup Mason installs may already be complete. Register terminal
-- events first, then do one initial scan to seed packages installed beforehand.
local registry = require("mason-registry")
local results = {}

registry:on("package:install:success", function(package)
  for _, expected_package in ipairs(expected) do
    if package.name == expected_package.package then
      results[package.name] = { status = "success" }
      print(("PACKAGE INSTALL SUCCESS %s"):format(package.name))
    end
  end
end)

registry:on("package:install:failed", function(package, err)
  for _, expected_package in ipairs(expected) do
    if package.name == expected_package.package then
      results[package.name] = { status = "failed", error = tostring(err) }
      print(("PACKAGE INSTALL FAILED %s: %s"):format(package.name, tostring(err)))
    end
  end
end)

for _, package in ipairs(expected) do
  if registry.is_installed(package.package) then
    results[package.package] = { status = "success", existing = true }
  end
end

local function all_finished()
  for _, package in ipairs(expected) do
    if not results[package.package] then
      return false
    end
  end
  return true
end

wait_for("Prettier and the JavaScript DAP adapter to finish installing", 240000, all_finished)

for _, package in ipairs(expected) do
  local result = results[package.package]
  assert(
    result.status == "success",
    ("%s installation failed: %s"):format(package.package, result.error or "unknown error")
  )

  local executable = vim.fn.exepath(package.executable)
  assert(
    executable ~= "",
    ("%s is installed but %s is not discoverable in Neovim PATH"):format(package.package, package.executable)
  )
  print(("EXECUTABLE %s: %s"):format(package.executable, executable))
end
pass("Prettier and JavaScript DAP binaries are discoverable after normal startup")

-- Installing the adapter is intentionally separate from loading the debugger.
for _, module in ipairs({ "dap", "dapui", "mason-nvim-dap", "nvim-dap-virtual-text" }) do
  assert(package.loaded[module] == nil, ("%s loaded during ordinary startup"):format(module))
end
pass("JavaScript DAP adapter is installed without loading the lazy DAP stack")

-- Confirm Conform can select the Mason-installed Prettier formatter on a
-- representative TypeScript buffer, and keep ESLint diagnostics single-owned.
local conform = require("conform")
local ts_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(ts_buf, vim.fn.tempname() .. ".tsx")
vim.bo[ts_buf].filetype = "typescriptreact"
local prettier = conform.get_formatter_info("prettier", ts_buf)
assert(prettier.available, "Conform cannot resolve the Mason-installed Prettier formatter")
pass("Conform can resolve Prettier for TSX buffers")

for _, filetype in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
  local linters = require("lint").linters_by_ft[filetype] or {}
  assert(not vim.tbl_contains(linters, "eslint"), "nvim-lint duplicates ESLint LSP for " .. filetype)
  assert(not vim.tbl_contains(linters, "eslint_d"), "nvim-lint duplicates ESLint LSP for " .. filetype)
end
pass("JavaScript/TypeScript diagnostics remain single-owned by ESLint LSP")
