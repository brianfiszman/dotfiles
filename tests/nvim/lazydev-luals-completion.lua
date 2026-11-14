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
  "local find_files = builtin.",
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
local completion_provider = client.server_capabilities.completionProvider
assert(type(completion_provider) == "table", "LuaLS did not advertise a completion provider")
assert(vim.tbl_contains(completion_provider.triggerCharacters or {}, "."),
  "LuaLS did not advertise dot-triggered field completion")

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

local function request_completion(line, character, context)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    -- Use the Insert-mode cursor position, after the last typed character.
    -- A Normal-mode cursor cannot sit after the last byte on the line.
    position = { line = line, character = character },
    context = context or { triggerKind = 2, triggerCharacter = "." },
  }
  local response, err = client:request_sync("textDocument/completion", params, 5000, bufnr)
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
  return labels
end

local function has_completion(labels, name)
  for label in pairs(labels) do
    if label == name or label:match("^" .. name .. "%s*%(") then
      return true
    end
  end
  return false
end

-- This mirrors the user's actual completion context after typing "builtin.".
local telescope_items = {}
assert(vim.wait(10000, function()
  telescope_items = request_completion(1, #"local find_files = builtin.")
  return telescope_items.find_files == true
end, 100), "LuaLS did not complete telescope.builtin.find_files; labels: "
  .. vim.inspect(vim.tbl_keys(telescope_items))
  .. "; workspace: "
  .. vim.inspect(Workspace.find({ buf = bufnr }).settings.Lua.workspace.library))

print("PASS: real LuaLS completion returns telescope.builtin.find_files")

-- Also verify the Neovim API type library and the configured global.
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  "local autocmd = vim.api.nvim_create_a",
})
local nvim_items = {}
assert(vim.wait(10000, function()
  nvim_items = request_completion(1, #"local autocmd = vim.api.nvim_create_a", { triggerKind = 1 })
  return has_completion(nvim_items, "nvim_create_autocmd")
end, 100), "LuaLS did not complete vim.api.nvim_create_autocmd from its typed prefix; labels: "
  .. vim.inspect(vim.tbl_keys(nvim_items)))

print("PASS: real LuaLS completion returns vim.api.nvim_create_autocmd")

-- Replace the intentionally incomplete completion context with valid Lua and ask
-- LuaLS to resolve a symbol from that now-valid expression.
local valid_line = "local find_files = builtin.find_files"
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
  'local builtin = require("telescope.builtin")',
  valid_line,
})

local hover_params = {
  textDocument = { uri = vim.uri_from_bufnr(bufnr) },
  position = {
    line = 1,
    character = #"local find_files = builtin." + 2,
  },
}
local hover_response, hover_err = client:request_sync("textDocument/hover", hover_params, 10000, bufnr)
assert(hover_response, "LuaLS hover request failed after valid Telescope usage: " .. tostring(hover_err))
assert(hover_response.err == nil, "LuaLS hover returned an error: " .. vim.inspect(hover_response.err))
assert(hover_response.result and hover_response.result.contents,
  "LuaLS could not resolve documentation for builtin.find_files after the valid edit")

-- The hover response is a server round-trip after didChange. Allow the
-- diagnostics debounce to settle, then assert that valid code is clean.
vim.wait(2000, function()
  return false
end, 100)

local diagnostics = vim.diagnostic.get(bufnr)
if #diagnostics > 0 then
  local messages = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(messages, diagnostic.message)
  end
  error("LuaLS reported diagnostics for valid Telescope API usage: " .. table.concat(messages, " | "))
end

print("PASS: LuaLS resolves hover for valid Telescope API usage")
print("PASS: valid Telescope API usage produces no LuaLS diagnostics")
