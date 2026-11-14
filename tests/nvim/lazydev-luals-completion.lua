-- End-to-end test: Lazydev must expose plugin and Neovim APIs to a real LuaLS process.
-- The workflow installs a pinned LuaLS binary and adds it to PATH before this test.

local luals = vim.fn.exepath("lua-language-server")
assert(luals ~= "", "lua-language-server is required for the Lazydev completion integration test")

local test_root = vim.env.NVIM_TEST_DIR
assert(test_root and test_root ~= "", "NVIM_TEST_DIR must be set by the headless test runner")

local workspace = test_root .. "/lua-ls-lazydev-fixture"
vim.fn.mkdir(workspace .. "/.git", "p")
local filename = workspace .. "/lazydev-telescope.lua"

local bufnr = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(bufnr, filename)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "local find_files = builtin.f",
})
vim.api.nvim_set_current_buf(bufnr)
vim.cmd("setfiletype lua")

assert(package.loaded["lazydev"] ~= nil, "opening a Lua buffer did not load Lazydev")

local function get_lua_ls_client()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if client.name == "lua_ls" then
      return client
    end
  end
end

assert(vim.wait(30000, function()
  return get_lua_ls_client() ~= nil
end, 100), "LuaLS did not attach to the Lazydev integration buffer")

local client = get_lua_ls_client()
assert(client and client.initialized, "LuaLS client did not finish initialization")

-- Lazydev completes plugin workspace registration on scheduled callbacks after
-- filetype activation and LspAttach. Wait for the effective workspace, not just
-- for the plugin module or LSP client to exist.
local Workspace = require("lazydev.workspace")
local telescope_plugin = require("lazy.core.config").plugins["telescope.nvim"]
assert(telescope_plugin and telescope_plugin.dir, "Telescope plugin directory is unavailable")
local telescope_lua = vim.fs.normalize(telescope_plugin.dir .. "/lua")

assert(vim.wait(10000, function()
  return vim.tbl_contains(Workspace.global().library, telescope_lua)
end, 100), "Lazydev did not register Telescope's Lua library in its global workspace")

assert(vim.wait(10000, function()
  local workspace = Workspace.find({ buf = bufnr })
  local libraries = workspace and vim.tbl_get(workspace.settings, "Lua", "workspace", "library") or {}
  return vim.tbl_contains(libraries, telescope_lua)
end, 100), "Lazydev did not apply Telescope's library to the active LuaLS workspace")

local function request_completion(line, character)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = character },
    context = { triggerKind = 1 },
  }
  local response, err = client:request_sync("textDocument/completion", params, 20000, bufnr)
  assert(response, "LuaLS completion request failed: " .. tostring(err))
  assert(response.err == nil,
    "LuaLS returned a completion error: " .. vim.inspect(response.err))

  local result = response.result
  local items = result and (result.items or result) or {}
  assert(type(items) == "table", "LuaLS returned an invalid completion result: " .. vim.inspect(response))

  local labels = {}
  for _, item in ipairs(items) do
    labels[item.label] = true
  end
  if vim.tbl_isempty(labels) then
    print("DEBUG: raw LuaLS completion response: " .. vim.inspect(response))
  end
  return labels
end

-- This mirrors the user's actual completion context after typing "builtin.".
local telescope_items = request_completion(1, #"local find_files = builtin.f")
if not telescope_items.find_files then
  print("DEBUG: LuaLS Telescope completion labels: " .. vim.inspect(vim.tbl_keys(telescope_items)))
  print("DEBUG: active LuaLS workspace: " .. vim.inspect(Workspace.find({ buf = bufnr }).settings.Lua.workspace.library))
end
assert(telescope_items.find_files,
  "LuaLS did not complete telescope.builtin.find_files; Lazydev's Telescope types are unavailable")

print("PASS: real LuaLS completion returns telescope.builtin.find_files")

-- Also verify the Neovim API type library and the configured global.
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "local autocmd = vim.api.n",
})
local nvim_items = request_completion(1, #"local autocmd = vim.api.n")
assert(nvim_items.nvim_create_autocmd,
  "LuaLS did not complete vim.api.nvim_create_autocmd; Neovim API types are unavailable")

print("PASS: real LuaLS completion returns vim.api.nvim_create_autocmd")

-- Replace the intentionally incomplete completion context with valid Lua and
-- wait for LuaLS to publish the resulting diagnostics before asserting clean.
local diagnostics_published = false
local group = vim.api.nvim_create_augroup("LazydevLuaLsCompletionTest", { clear = true })
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = group,
  buffer = bufnr,
  callback = function()
    -- Ignore the diagnostic from the intentionally incomplete completion
    -- context; pass only after LuaLS clears diagnostics for valid code.
    if #vim.diagnostic.get(bufnr) == 0 then
      diagnostics_published = true
    end
  end,
})

vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "local find_files = builtin.find_files",
})

assert(vim.wait(15000, function()
  return diagnostics_published
end, 100), "LuaLS did not publish diagnostics after the valid Telescope API usage was written")

local diagnostics = vim.diagnostic.get(bufnr)
if #diagnostics > 0 then
  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end
  error("LuaLS reported diagnostics for valid Telescope API usage: " .. table.concat(messages, " | "))
end

print("PASS: valid Telescope API usage produces no LuaLS diagnostics")
