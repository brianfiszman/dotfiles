-- Regression test for scope-aware indentation when replacing/opening lines.
-- Feed real user input, then assert from deferred callbacks after Neovim's
-- main input loop has processed it. Do not synchronously wait inside +luafile.
_G.DotfilesTestIndent = function()
  return 4
end

vim.cmd("enew!")
vim.bo.buftype = ""
vim.bo.bufhidden = "wipe"
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.autoindent = true
vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"

local function fail(message)
  vim.api.nvim_err_writeln(debug.traceback(tostring(message), 2))
  vim.cmd("cquit")
end

local function safely(callback)
  local ok, err = xpcall(callback, debug.traceback)
  if not ok then
    fail(err)
  end
end

local function wait_for_mode(expected, description, callback)
  local deadline = vim.uv.hrtime() + 1500000000
  local function poll()
    local current = vim.fn.mode():sub(1, 1)
    if current == expected then
      safely(callback)
    elseif vim.uv.hrtime() >= deadline then
      fail(description .. " did not reach mode " .. expected
        .. " (current mode: " .. vim.fn.mode() .. ")")
    else
      vim.defer_fn(poll, 10)
    end
  end
  vim.defer_fn(poll, 10)
end

local function press(keys, expected, description, callback)
  print("[indented-substitute] queueing " .. description)
  local queued = vim.api.nvim_input(keys)
  if queued <= 0 then
    fail(description .. " input was not queued")
    return
  end
  wait_for_mode(expected, description, function()
    print("[indented-substitute] " .. description .. " reached mode " .. expected)
    callback()
  end)
end

local function leave_insert(description, callback)
  press("<Esc>", "n", "Escape after " .. description, callback)
end

local function assert_current_line_indent(expected, description)
  local cursor = vim.api.nvim_win_get_cursor(0)
  assert(cursor[2] == expected, description .. " cursor column should be " .. expected)
  assert(vim.fn.indent(cursor[1]) == expected,
    description .. " line should have " .. expected .. " columns of indentation")
end

for key, description in pairs({
  S = "Reindent and replace line(s)",
  o = "Reindent and open line below",
  O = "Reindent and open line above",
}) do
  local mapping = vim.fn.maparg(key, "n", false, true)
  assert(mapping and mapping.expr == 1, key .. " must return the native edit sequence after reindent")
  assert(mapping.desc == description, key .. " mapping description changed")
end

local function set_lines(lines, cursor)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
end

local function finish()
  _G.DotfilesTestIndent = nil
  print("PASS: deterministic S, o, O and counted 2S preserve computed indentation")
  print("PASS: real Lua Treesitter indentation is preserved by S")
  print("PASS: real TypeScript Treesitter indentation is preserved by o and O")
  vim.cmd("qa!")
end

local run_typescript_O

local function run_typescript_o()
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "const options = {",
    "enabled: true,",
    "};",
  })
  vim.cmd("setfiletype typescript")
  assert(vim.bo.filetype == "typescript", "TypeScript fixture must set its filetype")
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    "TypeScript must use the configured Treesitter indentexpr (got: "
      .. vim.inspect(vim.bo.indentexpr) .. ")")
  local parser = vim.treesitter.get_parser(0, "typescript")
  assert(parser ~= nil, "TypeScript Treesitter parser must be available")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  press("o", "i", "TypeScript o with Treesitter indentation", function()
    assert_current_line_indent(2, "TypeScript o with Treesitter indentation")
    leave_insert("TypeScript o", function()
      run_typescript_O()
    end)
  end)
end

run_typescript_O = function()
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "const options = {",
    "enabled: true,",
    "};",
  })
  vim.cmd("setfiletype typescript")
  assert(vim.bo.filetype == "typescript", "TypeScript fixture must set its filetype")
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    "TypeScript must use the configured Treesitter indentexpr (got: "
      .. vim.inspect(vim.bo.indentexpr) .. ")")
  local parser = vim.treesitter.get_parser(0, "typescript")
  assert(parser ~= nil, "TypeScript Treesitter parser must be available")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  press("O", "i", "TypeScript O with Treesitter indentation", function()
    assert_current_line_indent(2, "TypeScript O with Treesitter indentation")
    leave_insert("TypeScript O", finish)
  end)
end

local function run_lua_treesitter()
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "local options = {",
    "enabled = true,",
    "}",
  })
  vim.cmd("setfiletype lua")
  assert(vim.bo.filetype == "lua", "Lua fixture must set its filetype")
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    "Lua must use the configured Treesitter indentexpr (got: "
      .. vim.inspect(vim.bo.indentexpr) .. ")")
  local parser = vim.treesitter.get_parser(0, "lua")
  assert(parser ~= nil, "Lua Treesitter parser must be available")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  press("S", "i", "Lua S with Treesitter indentation", function()
    assert_current_line_indent(2, "Lua S with Treesitter indentation")
    assert(vim.api.nvim_get_current_line() == "  ",
      "Lua S must preserve the computed Treesitter indentation")
    leave_insert("Lua S", run_typescript_o)
  end)
end

local function run_counted_substitute()
  set_lines({ "first", "second", "tail" }, { 1, 0 })
  press("2S", "i", "2S", function()
    assert(vim.api.nvim_buf_line_count(0) == 2,
      "2S must replace exactly two lines with one")
    assert_current_line_indent(4, "2S")
    leave_insert("2S", run_lua_treesitter)
  end)
end

local function run_open_above()
  set_lines({ "head", "tail" }, { 2, 0 })
  press("O", "i", "O", function()
    assert_current_line_indent(4, "O")
    leave_insert("O", run_counted_substitute)
  end)
end

local function run_open_below()
  set_lines({ "outer", "tail" }, { 1, 0 })
  press("o", "i", "o", function()
    assert_current_line_indent(4, "o")
    leave_insert("o", run_open_above)
  end)
end

set_lines({ "stale", "tail" }, { 1, 0 })
press("S", "i", "S", function()
  assert_current_line_indent(4, "S")
  assert(vim.api.nvim_get_current_line() == "    ",
    "S must preserve the deterministic computed indentation")
  leave_insert("S", run_open_below)
end)
