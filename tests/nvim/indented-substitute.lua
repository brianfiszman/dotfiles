-- Regression test for the custom S mapping. Use a deterministic indentexpr
-- so this test verifies the mapping's behavior independently of parser versions.
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

local mapping = vim.fn.maparg("S", "n", false, true)
assert(mapping and mapping.expr == 1, "S must use the expression mapping that reindents first")
assert(mapping.desc == "Reindent and replace line(s)", "S mapping description changed")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "stale", "tail" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys("S", "xt", false)

assert(vim.fn.mode() == "i", "S must enter Insert mode")
assert(vim.api.nvim_win_get_cursor(0)[2] == 4, "S must place the cursor after the computed four-space indentation")
assert(vim.api.nvim_get_current_line() == "    ", "S must retain the reindented whitespace")

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first", "second", "tail" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys("2S", "xt", false)

assert(vim.fn.mode() == "i", "counted S must enter Insert mode")
assert(vim.api.nvim_buf_line_count(0) == 2, "2S must replace exactly two lines with one")
assert(vim.api.nvim_win_get_cursor(0)[2] == 4, "counted S must retain computed indentation")

vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "xt", false)
_G.DotfilesTestIndent = nil

print("PASS: S reindents to the current scope before entering Insert mode")
print("PASS: counted S preserves its original line-range behavior and computed indentation")
