-- Regression test for scope-aware indentation with S, o and O.
--
-- The mapped commands must reindent the source line before opening the native
-- edit line. The TypeScript/Lua scenarios deliberately start with stale
-- whitespace and also assert that the source line itself was reindented, which
-- is the observable difference from the built-in commands.
--
-- Real input is queued with nvim_input() and asserted from deferred callbacks
-- after Neovim's main loop has processed it. This is a disposable headless
-- process: fail() exits non-zero immediately so a bad assertion can never turn
-- into a CI timeout.
--
-- The last scenario keeps a fold closed on purpose: native o opens at the fold
-- boundary there, so the mapping must skip the hidden source line instead of
-- reindenting it.
_G.DotfilesTestIndent = function()
  return 4
end

local function fail(message)
  io.stderr:write("[indented-substitute] FAIL: " .. debug.traceback(tostring(message), 2) .. "\n")
  io.stderr:flush()
  os.exit(1, true)
end

local function safely(callback)
  local ok, err = xpcall(callback, debug.traceback)
  if not ok then
    fail(err)
  end
end

local function buffer_state()
  return ("mode=%s cursor=%s buffer=%s"):format(
    vim.fn.mode(),
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  )
end

local function wait_until(predicate, description, callback)
  local deadline = vim.uv.hrtime() + 2000000000
  local function poll()
    if predicate() then
      safely(callback)
    elseif vim.uv.hrtime() >= deadline then
      fail(description .. " timed out (" .. buffer_state() .. ")")
    else
      vim.defer_fn(poll, 10)
    end
  end
  vim.defer_fn(poll, 10)
end

local function press(keys, description, callback)
  if vim.api.nvim_input(keys) <= 0 then
    fail(description .. ": input was not queued")
  end
  wait_until(function()
    return vim.fn.mode():sub(1, 1) == "i"
  end, description .. " did not enter Insert mode", callback)
end

local function leave_insert(description, callback)
  if vim.api.nvim_input("<Esc>") <= 0 then
    fail(description .. ": Escape was not queued")
  end
  wait_until(function()
    return vim.fn.mode():sub(1, 1) == "n"
  end, description .. " did not leave Insert mode", callback)
end

local function assert_insert(expected_row, expected_indent, description)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  assert(vim.fn.mode():sub(1, 1) == "i",
    description .. " must be in Insert mode (" .. buffer_state() .. ")")
  assert(cursor[1] == expected_row,
    ("%s row expected %d, got %d (%s)"):format(description, expected_row, cursor[1], buffer_state()))
  assert(vim.fn.indent(cursor[1]) == expected_indent,
    ("%s indent expected %d, got %d (%s)"):format(
      description, expected_indent, vim.fn.indent(cursor[1]), buffer_state()))
  assert(cursor[2] == expected_indent,
    ("%s column expected %d, got %d (%s)"):format(
      description, expected_indent, cursor[2], buffer_state()))
  assert(line == string.rep(" ", expected_indent),
    ("%s must leave an empty indented line, got %s"):format(description, vim.inspect(line)))
  print(("[indented-substitute] %s: row=%d column=%d indent=%d"):format(
    description, cursor[1], cursor[2], vim.fn.indent(cursor[1])))
end

local function set_buffer(lines, cursor)
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.bo.autoindent = true
  vim.bo.smartindent = false
  -- Fixtures stay unfolded so indentation assertions are about the mapping.
  -- The closed-fold control opts back into folding explicitly.
  vim.wo.foldenable = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
  assert(vim.fn.foldclosed(cursor[1]) == -1,
    "fixture must not hide the source line in a closed fold")
end

local function deterministic_fixture(lines, cursor)
  set_buffer(lines, cursor)
  vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"
end

local function treesitter_fixture(filetype, lines, cursor)
  set_buffer(lines, cursor)
  vim.cmd("setfiletype " .. filetype)
  assert(vim.bo.filetype == filetype,
    "fixture filetype expected " .. filetype .. ", got " .. vim.inspect(vim.bo.filetype))
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    filetype .. " must use the configured Treesitter indentexpr (got "
      .. vim.inspect(vim.bo.indentexpr) .. ")")
  local parser = vim.treesitter.get_parser(0, filetype)
  assert(parser ~= nil, filetype .. " Treesitter parser must be available")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, cursor)
  assert(vim.fn.foldclosed(cursor[1]) == -1,
    "fixture must not hide the source line in a closed fold")
end

-- Reindent once with the same engine used by the mapping, record the result,
-- then restore stale whitespace so the mapped command has to compute it again.
local function expected_indent_and_reset(row, stale_line)
  local view = vim.fn.winsaveview()
  vim.cmd.normal({ args = { "==" }, bang = true })
  local expected = vim.fn.indent(row)
  vim.fn.winrestview(view)
  assert(expected > 0,
    "Treesitter must compute a nested indentation for the fixture (got " .. expected .. ")")
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { stale_line })
  vim.treesitter.get_parser(0, vim.bo.filetype):parse()
  vim.api.nvim_win_set_cursor(0, { row, 0 })
  assert(vim.fn.indent(row) == 0, "fixture must start from stale indentation")
  return expected
end

local function assert_source_reindented(row, expected, stale_line, description)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  assert(vim.fn.indent(row) == expected,
    ("%s must reindent the source line to %d, got %d"):format(
      description, expected, vim.fn.indent(row)))
  assert(line == string.rep(" ", expected) .. stale_line,
    ("%s source line expected %s, got %s"):format(
      description, vim.inspect(string.rep(" ", expected) .. stale_line), vim.inspect(line)))
end

for key, description in pairs({
  S = "Reindent and replace line(s)",
  o = "Reindent and open line below",
  O = "Reindent and open line above",
}) do
  local mapping = vim.fn.maparg(key, "n", false, true)
  assert(mapping and mapping.expr == 0, key .. " must use a callback mapping")
  assert(mapping.desc == description, key .. " mapping description changed")
end

local function finish()
  _G.DotfilesTestIndent = nil
  print("PASS: deterministic S, o, O and counted 2S use the computed indentation")
  print("PASS: real Lua Treesitter indentation survives S")
  print("PASS: real TypeScript Treesitter indentation reindents the source for o and O")
  print("PASS: a closed fold keeps native o at the fold boundary and hides the source")
  os.exit(0, true)
end

local function run_closed_fold_control()
  set_buffer({ "fold head", "  stale", "fold tail" }, { 2, 0 })
  vim.wo.foldmethod = "manual"
  vim.wo.foldenable = true
  vim.cmd("1,3fold")
  assert(vim.fn.foldclosed(2) ~= -1,
    "control fixture must hide the stale source line in a closed fold")
  press("o", "closed-fold o", function()
    -- Native o on a closed fold opens after the whole fold, not after the
    -- hidden source line. The fold start line has no indentation to copy.
    assert_insert(4, 0, "closed-fold o")
    assert(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "  stale",
      "closed-fold o must not reindent the hidden source line")
    assert(vim.fn.foldclosed(2) ~= -1,
      "closed-fold o must leave the fold closed (" .. buffer_state() .. ")")
    leave_insert("closed-fold o", finish)
  end)
end

local run_typescript_open_above

local function run_typescript_open_below()
  treesitter_fixture("typescript", {
    "const options = {",
    "enabled: true,",
    "};",
  }, { 2, 0 })
  local expected = expected_indent_and_reset(2, "enabled: true,")
  press("o", "TypeScript o", function()
    assert_insert(3, expected, "TypeScript o")
    assert_source_reindented(2, expected, "enabled: true,", "TypeScript o")
    leave_insert("TypeScript o", run_typescript_open_above)
  end)
end

run_typescript_open_above = function()
  treesitter_fixture("typescript", {
    "const options = {",
    "enabled: true,",
    "};",
  }, { 2, 0 })
  local expected = expected_indent_and_reset(2, "enabled: true,")
  press("O", "TypeScript O", function()
    assert_insert(2, expected, "TypeScript O")
    assert_source_reindented(3, expected, "enabled: true,", "TypeScript O")
    leave_insert("TypeScript O", run_closed_fold_control)
  end)
end

local function run_lua_substitute()
  treesitter_fixture("lua", {
    "local options = {",
    "enabled = true,",
    "}",
  }, { 2, 0 })
  local expected = expected_indent_and_reset(2, "enabled = true,")
  press("S", "Lua S", function()
    assert_insert(2, expected, "Lua S")
    leave_insert("Lua S", run_typescript_open_below)
  end)
end

local function run_counted_substitute()
  deterministic_fixture({ "one", "two", "tail" }, { 1, 0 })
  press("2S", "2S", function()
    assert(vim.api.nvim_buf_line_count(0) == 2,
      "2S must replace exactly two lines with one (" .. buffer_state() .. ")")
    assert_insert(1, 4, "2S")
    leave_insert("2S", run_lua_substitute)
  end)
end

local function run_open_above()
  deterministic_fixture({ "head", "stale" }, { 2, 0 })
  press("O", "O", function()
    assert_insert(2, 4, "O")
    leave_insert("O", run_counted_substitute)
  end)
end

local function run_open_below()
  deterministic_fixture({ "stale", "tail" }, { 1, 0 })
  press("o", "o", function()
    assert_insert(2, 4, "o")
    leave_insert("o", run_open_above)
  end)
end

deterministic_fixture({ "stale", "tail" }, { 1, 0 })
press("S", "S", function()
  assert_insert(1, 4, "S")
  leave_insert("S", run_open_below)
end)
