local M = {}

local function checked(result, description)
  assert(result.code == 0,
    ("%s failed with exit %s\n%s\n%s"):format(
      description,
      tostring(result.code),
      result.stdout or "",
      result.stderr or ""
    ))
end

-- Replace a native library without modifying the inode currently mapped by
-- dlopen(). A direct copy/truncate can corrupt the loaded image before its
-- finalizer runs during Neovim shutdown.
function M.replace_file_atomically(source, destination)
  local temporary = ("%s.tmp-%s-%s"):format(
    destination,
    tostring(vim.fn.getpid()),
    tostring(vim.uv.hrtime())
  )

  local copied, copy_error = vim.uv.fs_copyfile(source, temporary)
  if not copied then
    error(("Could not copy %s to temporary file %s: %s"):format(
      source, temporary, tostring(copy_error)
    ))
  end

  local renamed, rename_error = vim.uv.fs_rename(temporary, destination)
  if not renamed then
    pcall(vim.uv.fs_unlink, temporary)
    error(("Could not atomically replace %s with %s: %s"):format(
      destination, source, tostring(rename_error)
    ))
  end
end

function M.build(plugin)
  local result = vim.system({ "make", "jsregexp" }, {
    cwd = plugin.dir,
    text = true,
  }):wait()
  checked(result, "LuaSnip jsregexp compilation")

  local lua_source = plugin.dir .. "/deps/jsregexp/jsregexp.lua"
  local lua_destination = plugin.dir .. "/lua/luasnip-jsregexp.lua"
  assert(vim.fn.filereadable(lua_source) == 1,
    "LuaSnip jsregexp Lua source is missing: " .. lua_source)
  M.replace_file_atomically(lua_source, lua_destination)

  -- Match upstream's cleanup of the legacy location, but never overwrite the
  -- deps/luasnip-jsregexp.so file in place: LuaSnip may already have dlopen'ed it.
  pcall(vim.uv.fs_unlink, plugin.dir .. "/lua/luasnip-jsregexp.so")
  M.replace_file_atomically(
    plugin.dir .. "/deps/jsregexp/jsregexp.so",
    plugin.dir .. "/deps/luasnip-jsregexp.so"
  )
end

return M
