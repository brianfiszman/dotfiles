-- Verify Avante's Rust template module can actually be loaded by this Neovim.
-- A file-existence check is insufficient: dlopen can still fail because of an
-- incompatible binary, missing dependency, or an invalid Lua module export.

local plugin_root = vim.fn.stdpath("data") .. "/lazy/avante.nvim"
local lua_dir = plugin_root .. "/lua"
local library = lua_dir .. "/avante_templates.so"

assert(vim.fn.isdirectory(plugin_root) == 1,
  "Avante plugin directory is missing: " .. plugin_root)
assert(vim.fn.filereadable(library) == 1,
  "Avante prebuilt template library is missing: " .. library)

-- Keep this check independent of whether Lazy has loaded Avante's Lua plugin.
package.cpath = lua_dir .. "/?.so;" .. package.cpath

local ok, templates = pcall(require, "avante_templates")
assert(ok, "Avante template library exists but cannot be loaded: " .. tostring(templates))
assert(type(templates) == "table", "avante_templates must return a Lua module table")
assert(type(templates.initialize) == "function",
  "avante_templates.initialize is missing")
assert(type(templates.render) == "function",
  "avante_templates.render is missing")

print("PASS: avante_templates native library is loadable and exports initialize/render")
vim.cmd("qa!")
