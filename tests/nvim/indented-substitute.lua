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
  io.stderr:write("[indented-substitute] FAIL: " .. debug.traceback(tostring(message), 2) .. "\n")
  io.stderr:flush()
  -- This file runs in a disposable headless Neovim process. Exit immediately
  -- with a failing status so a deferred assertion can never become a 5m timeout.
  os.exit(1, true)
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

local function assert_current_line_indent(expected, description, expected_row)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local actual_indent = vim.fn.indent(cursor[1])
  local line = vim.api.nvim_get_current_line()
  print(("[indented-substitute] %s: row=%d column=%d indent=%d line=%s"):format(
    description, cursor[1], cursor[2], actual_indent, vim.inspect(line)))
  if expected_row then
    assert(cursor[1] == expected_row,
      description .. " row expected " .. expected_row .. " (actual=" .. cursor[1] .. ")")
  end
  assert(cursor[2] == expected,
    description .. " cursor column expected " .. expected
      .. " (actual cursor=" .. cursor[2] .. ", indent=" .. actual_indent
      .. ", line=" .. vim.inspect(line) .. ")")
  assert(actual_indent == expected,
    description .. " line indent expected " .. expected
      .. " (actual=" .. actual_indent .. ", line=" .. vim.inspect(line) .. ")")
end

for key, description in pairs({
  S = "Reindent and replace line(s)",
  o = "Reindent and open line below",
  O = "Reindent and open line above",
}) do
  local mapping = vim.fn.maparg(key, "n", false, true)
  assert(mapping and mapping.expr == 0, key .. " must use a non-expression callback mapping")
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
  -- This is a standalone disposable Neovim process; exit directly after all
  -- deferred input callbacks and assertions have completed.
  os.exit(0, true)
end

local function setup_typescript_buffer()
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
  assert(vim.bo.autoindent, "TypeScript fixture must use autoindent while native edit line is opened")
  print(("[indented-substitute] TypeScript options: autoindent=%s smartindent=%s copyindent=%s expandtab=%s shiftwidth=%d indentexpr=%s"):format(
    tostring(vim.bo.autoindent), tostring(vim.bo.smartindent),
    tostring(vim.bo.copyindent), tostring(vim.bo.expandtab),
    vim.bo.shiftwidth, vim.inspect(vim.bo.indentexpr)))
  local parser = vim.treesitter.get_parser(0, "typescript")
  assert(parser ~= nil, "TypeScript Treesitter parser must be available")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  -- Obtain the expected scope indentation from this exact parser/query and
  -- active indentexpr, rather than assuming a hard-coded two-space result.
  vim.cmd("normal! ==")
  local expected = vim.fn.indent(2)
  assert(expected > 0,
    "TypeScript Treesitter query did not compute a nested object indentation")
  print("[indented-substitute] TypeScript indentexpr computed " .. expected
    .. " columns; source after control ==: " .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)))

  -- Restore stale whitespace so the mapped action must recalculate it again.
  vim.api.nvim_buf_set_lines(0, 1, 2, false, { "enabled: true," })
  parser:parse()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  print("[indented-substitute] TypeScript source reset before mapped action: "
    .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))
    .. "; cursor=" .. vim.inspect(vim.api.nvim_win_get_cursor(0)))
  return expected
end

local run_typescript_O

local function run_typescript_o()
  local expected = setup_typescript_buffer()
  press("o", "i", "TypeScript o with Treesitter indentation", function()
    assert_current_line_indent(expected, "TypeScript o with Treesitter indentation", 3)
    assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
      "TypeScript indentexpr must be restored before user input")
    assert(vim.api.nvim_get_current_line() == string.rep(" ", expected),
      "TypeScript o must copy the reindented scope prefix")
    leave_insert("TypeScript o", function()
      run_typescript_O()
    end)
  end)
end

run_typescript_O = function()
  local expected = setup_typescript_buffer()
  press("O", "i", "TypeScript O with Treesitter indentation", function()
    assert_current_line_indent(expected, "TypeScript O with Treesitter indentation", 2)
    assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
      "TypeScript indentexpr must be restored before user input")
    assert(vim.api.nvim_get_current_line() == string.rep(" ", expected),
      "TypeScript O must copy the reindented scope prefix")
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
    assert_current_line_indent(2, "Lua S with Treesitter indentation", 2)
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
    assert_current_line_indent(4, "2S", 1)
    leave_insert("2S", run_lua_treesitter)
  end)
end

local function run_open_above()
  set_lines({ "head", "tail" }, { 2, 0 })
  press("O", "i", "O", function()
    assert_current_line_indent(4, "O", 2)
    leave_insert("O", run_counted_substitute)
  end)
end

local function run_open_below()
  set_lines({ "outer", "tail" }, { 1, 0 })
  press("o", "i", "o", function()
    assert_current_line_indent(4, "o", 2)
    leave_insert("o", run_open_above)
  end)
end

set_lines({ "stale", "tail" }, { 1, 0 })
press("S", "i", "S", function()
  assert_current_line_indent(4, "S", 1)
  assert(vim.api.nvim_get_current_line() == "    ",
    "S must preserve the deterministic computed indentation")
  leave_insert("S", run_open_below)
end)
