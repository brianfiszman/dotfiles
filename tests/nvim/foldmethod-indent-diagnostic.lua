-- Compare the real O mapping with the repository's configured folding modes.
-- This records behavior instead of asserting a preferred result: the purpose is
-- to distinguish foldmethod effects from closed-fold effects and indentation.
local path = vim.fn.tempname() .. ".js"
local source = {
  "function build() {",
  "if (true) {",
  "return true;",
  "}",
  "}",
}

local function fail(message)
  io.stderr:write("[foldmethod-diagnostic] FAIL: " .. debug.traceback(tostring(message), 2) .. "\n")
  io.stderr:flush()
  os.exit(1, true)
end

local function wait_for_mode(expected, description, callback)
  local deadline = vim.uv.hrtime() + 5000000000
  local function poll()
    if vim.fn.mode():sub(1, 1) == expected then
      local ok, err = xpcall(callback, debug.traceback)
      if not ok then
        fail(err)
      end
    elseif vim.uv.hrtime() >= deadline then
      fail(description .. " timed out; mode=" .. vim.fn.mode()
        .. ", filetype=" .. vim.bo.filetype
        .. ", foldmethod=" .. vim.wo.foldmethod
        .. ", foldenable=" .. tostring(vim.wo.foldenable)
        .. ", foldclosed(3)=" .. vim.fn.foldclosed(3))
    else
      vim.defer_fn(poll, 10)
    end
  end
  vim.defer_fn(poll, 10)
end

local cases = {
  { label = "manual-open", method = "manual", enabled = true, level = 99, close = false },
  { label = "syntax-open", method = "syntax", enabled = true, level = 99, close = false },
  { label = "syntax-disabled", method = "syntax", enabled = false, level = 0, close = true },
  { label = "syntax-closed", method = "syntax", enabled = true, level = 0, close = true },
}

local function run_case(index)
  local case = cases[index]
  if not case then
    vim.fn.delete(path)
    print("[foldmethod-diagnostic] PASS: all folding variants completed")
    os.exit(0, true)
    return
  end

  assert(vim.fn.writefile(source, path) == 0, "could not write JavaScript fixture")
  vim.cmd("enew!")
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  assert(vim.bo.filetype == "javascript",
    "expected javascript filetype, got " .. vim.inspect(vim.bo.filetype))
  assert(vim.bo.indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()",
    "expected the configured Treesitter indentexpr, got " .. vim.inspect(vim.bo.indentexpr))

  local parser = vim.treesitter.get_parser(0)
  parser:parse()
  assert(parser:lang() == "javascript",
    "expected the javascript parser, got " .. tostring(parser:lang()))

  vim.wo.foldmethod = case.method
  vim.wo.foldenable = case.enabled
  vim.wo.foldlevel = case.level
  vim.cmd("normal! zx")
  if case.close then
    vim.cmd("normal! zM")
  else
    vim.cmd("normal! zR")
  end
  vim.api.nvim_win_set_cursor(0, { 3, 0 })

  local indent_ok = vim.bo.indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()"
  local computed_indent = vim.fn.indent(3)
  local before = {
    version = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    variant = case.label,
    filetype = vim.bo.filetype,
    parser = parser:lang(),
    indentexpr = vim.bo.indentexpr,
    foldmethod = vim.wo.foldmethod,
    foldenable = vim.wo.foldenable,
    foldlevel = vim.wo.foldlevel,
    foldclosed_source = vim.fn.foldclosed(3),
    foldlevel_source = vim.fn.foldlevel(3),
    source_indent = vim.fn.indent(3),
    treesitter_indent_ok = indent_ok,
    treesitter_indent = tostring(computed_indent),
  }
  print("[foldmethod-diagnostic] BEFORE " .. vim.inspect(before))

  if vim.api.nvim_input("O") <= 0 then
    fail(case.label .. ": O input was not queued")
  end

  wait_for_mode("i", case.label .. ": O did not enter Insert mode", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local after = {
      variant = case.label,
      row = cursor[1],
      column = cursor[2],
      indent = vim.fn.indent(cursor[1]),
      foldclosed_source = vim.fn.foldclosed(3),
      buffer = vim.api.nvim_buf_get_lines(0, 0, -1, false),
    }
    print("[foldmethod-diagnostic] AFTER " .. vim.inspect(after))

    if vim.api.nvim_input("<Esc>") <= 0 then
      fail(case.label .. ": Escape input was not queued")
    end
    wait_for_mode("n", case.label .. ": Escape did not return to Normal mode", function()
      run_case(index + 1)
    end)
  end)
end

vim.defer_fn(function()
  fail("foldmethod diagnostic exceeded 60 seconds")
end, 60000)

run_case(1)
