-- Regression test for scope-aware indentation when replacing/opening lines.
-- Use a deterministic indentexpr so assertions do not depend on parser versions.
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

local function press_and_wait_for_insert(keys, description)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "mtx!", false)
  assert(vim.fn.mode():sub(1, 1) == "i", description .. " must enter Insert mode")
end

local function leave_insert()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
  assert(vim.fn.mode():sub(1, 1) == "n", "Escape must return to Normal mode")
end

local function assert_current_line_indent(expected, description)
  local cursor = vim.api.nvim_win_get_cursor(0)
  assert(cursor[2] == expected, description .. " cursor column should be " .. expected)
  assert(vim.fn.indent(vim.api.nvim_win_get_cursor(0)[1]) == expected,
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

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "stale", "tail" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
press_and_wait_for_insert("S", "S")
assert_current_line_indent(4, "S")
assert(vim.api.nvim_get_current_line() == "    ", "S must preserve the computed indentation")
leave_insert()

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "outer", "tail" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
press_and_wait_for_insert("o", "o")
assert_current_line_indent(4, "o")
leave_insert()

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "head", "tail" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
press_and_wait_for_insert("O", "O")
assert_current_line_indent(4, "O")
leave_insert()

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first", "second", "tail" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
press_and_wait_for_insert("2S", "2S")
assert(vim.api.nvim_buf_line_count(0) == 2, "2S must replace exactly two lines with one")
assert_current_line_indent(4, "2S")
leave_insert()

_G.DotfilesTestIndent = nil

print("PASS: S reindents to the current scope before entering Insert mode")
print("PASS: o and O open new lines at the computed scope indentation")
print("PASS: counted S preserves its line-range behavior and computed indentation")

-- Exercise the real Treesitter indentation provider used by this repository.
-- nvim-treesitter is pinned in lazy-lock.json; Lua has its own indents query,
-- while TypeScript inherits the pinned ECMA indentation query.
local function new_treesitter_indent_buffer(filetype, lines)
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("setfiletype " .. filetype)

  assert(vim.bo.filetype == filetype, filetype .. " fixture must set its filetype")
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    filetype .. " must use the configured nvim-treesitter indentexpr (got: "
      .. vim.inspect(vim.bo.indentexpr) .. ")")

  local parser = vim.treesitter.get_parser(0, filetype)
  assert(parser ~= nil, filetype .. " Treesitter parser must be available")
  parser:parse()
end

new_treesitter_indent_buffer("lua", {
  "local options = {",
  "enabled = true,",
  "}",
})
vim.api.nvim_win_set_cursor(0, { 2, 0 })
press_and_wait_for_insert("S", "Lua S with Treesitter indentation")
assert_current_line_indent(2, "Lua S with Treesitter indentation")
leave_insert()

new_treesitter_indent_buffer("typescript", {
  "const options = {",
  "enabled: true,",
  "};",
})
vim.api.nvim_win_set_cursor(0, { 2, 0 })
press_and_wait_for_insert("o", "TypeScript o with Treesitter indentation")
assert_current_line_indent(2, "TypeScript o with Treesitter indentation")
leave_insert()

new_treesitter_indent_buffer("typescript", {
  "const options = {",
  "enabled: true,",
  "};",
})
vim.api.nvim_win_set_cursor(0, { 2, 0 })
press_and_wait_for_insert("O", "TypeScript O with Treesitter indentation")
assert_current_line_indent(2, "TypeScript O with Treesitter indentation")
leave_insert()

print("PASS: real Lua Treesitter indentation is preserved by S")
print("PASS: real TypeScript Treesitter indentation is preserved by o and O")

