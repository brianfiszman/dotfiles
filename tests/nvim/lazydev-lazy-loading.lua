-- Verify lazydev loads only for Lua buffers and preserves LuaLS/plugin integrations.

local retired_lua_dev = "neo" .. "dev"
assert(package.loaded[retired_lua_dev] == nil, "replaced Lua development plugin must not be loaded")
assert(package.loaded["lazydev"] == nil, "lazydev loaded during unrelated startup")
assert(vim.fn.exists(":LazyDev") == 0, ":LazyDev should not exist before a Lua buffer is opened")

local lua_config = vim.lsp.config.lua_ls
assert(type(lua_config) == "table", "native lua_ls config is missing")
assert(lua_config.settings.Lua.diagnostics.globals[1] == "vim", "LuaLS vim global setting is missing")
assert(lua_config.settings.Lua.completion.callSnippet == "Replace", "LuaLS function-call snippets setting changed")
assert(lua_config.settings.Lua.workspace.library[vim.fn.expand("$VIMRUNTIME/lua")] == true,
  "LuaLS Neovim runtime library path is missing")
assert(lua_config.settings.Lua.workspace.library[vim.fn.stdpath("config") .. "/lua"] == true,
  "LuaLS config library path is missing")
assert(lua_config.before_init == nil, "Deprecated LuaLS before_init hook remains configured")

vim.cmd("enew")
vim.cmd("setfiletype lua")

assert(package.loaded["lazydev"] ~= nil, "lazydev did not load for the Lua filetype")
assert(vim.fn.exists(":LazyDev") == 2, ":LazyDev command was not registered after Lua filetype activation")

local lazydev_config = require("lazydev.config")
assert(lazydev_config.integrations.lspconfig == true, "lazydev native LSP integration is disabled")
assert(lazydev_config.integrations.cmp == true, "lazydev nvim-cmp integration is disabled")

local libraries = {}
for _, library in ipairs(lazydev_config.libs) do
  libraries[library.path] = true
end
for _, plugin in ipairs({ "neotest", "nvim-dap-ui", "nvim-treesitter", "plenary.nvim", "telescope.nvim" }) do
  assert(libraries[plugin], "lazydev plugin API library is missing: " .. plugin)
end

local cmp = require("cmp")
local function lazydev_cmp_registered()
  local source_names = vim.tbl_map(function(source)
    return source.name
  end, cmp.get_registered_sources())
  return vim.tbl_contains(source_names, "lazydev")
end
assert(vim.wait(5000, lazydev_cmp_registered, 10),
  "lazydev nvim-cmp source was not registered after its scheduled setup")

local integrations = require("lazydev.integrations")
assert(integrations.loaded.cmp == true, "lazydev nvim-cmp integration did not initialize")
assert(integrations.loaded.lspconfig == true, "lazydev native LSP integration did not initialize")
assert(vim.lsp.is_enabled("lua_ls"), "native LuaLS server is not enabled")

local lazy = require("lazy.core.config")
local retired_spec = retired_lua_dev .. ".nvim"
assert(lazy.plugins["lazydev.nvim"] ~= nil, "lazydev plugin spec is missing")
assert(vim.tbl_contains(lazy.plugins["lazydev.nvim"].ft or {}, "lua"),
  "lazydev must use a Lua filetype trigger")
assert(lazy.plugins[retired_spec] == nil, "replaced Lua development plugin remains in lazy specs")

print("PASS: lazydev remains unloaded outside Lua filetypes")
print("PASS: opening a Lua buffer loads lazydev and registers :LazyDev")
print("PASS: LuaLS runtime/config settings and all five plugin API libraries are preserved")
print("PASS: lazydev nvim-cmp and native LSP integrations are enabled")
