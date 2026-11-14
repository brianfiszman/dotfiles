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
  "builtin.",
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

local function request_completion(line, character)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = character },
    context = { triggerKind = 1 },
  }
  local response, err = client:request_sync("textDocument/completion", params, 20000, bufnr)
  assert(response, "LuaLS completion request failed: " .. tostring(err))

  local result = response.result
  local items = result and (result.items or result) or {}
  assert(type(items) == "table", "LuaLS returned an invalid completion result")

  local labels = {}
  for _, item in ipairs(items) do
    labels[item.label] = true
  end
  return labels
end

-- This mirrors the user's actual completion context after typing "builtin.".
local telescope_items = request_completion(1, #"builtin.")
assert(telescope_items.find_files,
  "LuaLS did not complete telescope.builtin.find_files; Lazydev's Telescope types are unavailable")

print("PASS: real LuaLS completion returns telescope.builtin.find_files")

-- Also verify the Neovim API type library and the configured global.
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "vim.api.",
})
local nvim_items = request_completion(1, #"vim.api.")
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
    diagnostics_published = true
  end,
})

vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "return builtin.find_files",
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
