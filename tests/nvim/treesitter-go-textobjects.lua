-- End-to-end coverage for Go textobjects on nvim-treesitter/main.
-- The standalone textobjects plugin owns these mappings; go.nvim's legacy
-- nvim-treesitter.configs integration is explicitly disabled.

local function feed(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, "mtx", false)
end

local function find_line(source, value, start_at)
  for row = start_at or 1, #source do
    if source[row] == value then
      return row
    end
  end
  error("Go fixture is missing line: " .. value)
end

local function selection_range()
  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  local first = { anchor[2], anchor[3] }
  local last = { cursor[2], cursor[3] }
  if first[1] > last[1] or (first[1] == last[1] and first[2] > last[2]) then
    first, last = last, first
  end
  return { first[1], first[2], last[1], last[2] }
end

local function wait_for_visual(description)
  assert(vim.wait(2000, function()
    return vim.fn.mode():sub(1, 1) == "v"
  end, 10), description .. " did not enter Visual mode (mode=" .. vim.fn.mode() .. ")")
end

local function assert_selected_rows(range, first, last, description)
  assert(range[1] == first and range[3] == last,
    ("%s: expected selected rows %d-%d, got %d-%d (%s)"):format(
      description, first, last, range[1], range[3], vim.inspect(range)))
end

local source = {
  "package main",
  "",
  "type Config struct {",
  "    Enabled bool",
  "    Name string",
  "}",
  "",
  "func build() int {",
  "    value := 1",
  "    return value",
  "}",
  "",
  "func run() {",
  "    _ = build()",
  "}",
}
local path = vim.fn.tempname() .. ".go"
assert(vim.fn.writefile(source, path) == 0, "Could not write Go textobjects fixture")
vim.cmd("edit " .. vim.fn.fnameescape(path))

assert(vim.bo.filetype == "go", "Go fixture filetype was not detected")
assert(package.loaded["go"] ~= nil, "Go filetype did not lazy-load go.nvim")
assert(package.loaded["nvim-treesitter-textobjects"] ~= nil,
  "The standalone nvim-treesitter-textobjects plugin did not load")
assert(package.loaded["nvim-treesitter.configs"] == nil,
  "The removed legacy nvim-treesitter.configs module was loaded")

local parser = vim.treesitter.get_parser(0)
assert(parser:lang() == "go", "Expected the Go Treesitter parser")
parser:parse()

local mappings = {
  { "x", "af" }, { "o", "af" }, { "x", "if" }, { "o", "if" },
  { "x", "ac" }, { "o", "ac" }, { "x", "ic" }, { "o", "ic" },
  { "n", "]]" }, { "n", "][" }, { "n", "[[" }, { "n", "[]" },
}
for _, item in ipairs(mappings) do
  local map = vim.fn.maparg(item[2], item[1], false, true)
  assert(map and map.buffer == 1,
    ("Go textobject mapping %s in mode %s is not buffer-local"):format(item[2], item[1]))
end
print("PASS: Go textobject select and movement mappings are buffer-local and registered")

local type_start = find_line(source, "type Config struct {")
local enabled_row = find_line(source, "    Enabled bool")
local name_row = find_line(source, "    Name string")
local type_end = find_line(source, "}", type_start + 1)
local build_start = find_line(source, "func build() int {")
local value_row = find_line(source, "    value := 1")
local return_row = find_line(source, "    return value")
local build_end = find_line(source, "}", build_start + 1)
local run_start = find_line(source, "func run() {")
local run_end = find_line(source, "}", run_start + 1)

vim.api.nvim_win_set_cursor(0, { value_row, 3 })
feed("vaf")
wait_for_visual("Go af")
assert_selected_rows(selection_range(), build_start, build_end, "Go af selects the outer function")
print("PASS: af selects the complete Go function")
feed("<Esc>")

vim.api.nvim_win_set_cursor(0, { value_row, 3 })
feed("vif")
wait_for_visual("Go if")
assert_selected_rows(selection_range(), value_row, return_row, "Go if selects the function body")
print("PASS: if selects the Go function body")
feed("<Esc>")

vim.api.nvim_win_set_cursor(0, { enabled_row, 5 })
feed("vac")
wait_for_visual("Go ac")
assert_selected_rows(selection_range(), type_start, type_end, "Go ac selects the outer type declaration")
print("PASS: ac selects the complete Go struct declaration")
feed("<Esc>")

vim.api.nvim_win_set_cursor(0, { enabled_row, 5 })
feed("vic")
wait_for_visual("Go ic")
local inner_type = selection_range()
assert(inner_type[1] >= type_start and inner_type[1] <= enabled_row
    and inner_type[3] >= name_row and inner_type[3] <= type_end,
  ("Go ic did not select the struct fields: %s"):format(vim.inspect(inner_type)))
print("PASS: ic selects the Go struct body")
feed("<Esc>")

vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("]]")
local cursor = vim.api.nvim_win_get_cursor(0)
assert(cursor[1] == build_start,
  ("] ] did not move to the first Go function: expected row %d, got %d"):format(build_start, cursor[1]))
feed("]]")
cursor = vim.api.nvim_win_get_cursor(0)
assert(cursor[1] == run_start,
  ("] ] did not move to the next Go function: expected row %d, got %d"):format(run_start, cursor[1]))
feed("[[")
cursor = vim.api.nvim_win_get_cursor(0)
assert(cursor[1] == build_start,
  ("[ [ did not return to the previous Go function: expected row %d, got %d"):format(build_start, cursor[1]))
feed("][")
cursor = vim.api.nvim_win_get_cursor(0)
assert(cursor[1] == build_end,
  ("] [ did not move to the Go function end: expected row %d, got %d"):format(build_end, cursor[1]))
vim.api.nvim_win_set_cursor(0, { run_start, 0 })
feed("[]")
cursor = vim.api.nvim_win_get_cursor(0)
assert(cursor[1] == build_end,
  ("[ ] did not move to the previous Go function end: expected row %d, got %d"):format(build_end, cursor[1]))
print("PASS: ]], ][, [[ and [] navigate Go function boundaries")

vim.fn.delete(path)
print("PASS: Go textobjects use the standalone current Treesitter API without the legacy configs module")
