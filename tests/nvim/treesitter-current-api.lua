-- End-to-end test for the current nvim-treesitter main API.
-- Requires the real Mason-installed tree-sitter CLI and compiled parsers.

local function fail(message)
  io.stderr:write("[treesitter-current-api] FAIL: " .. debug.traceback(tostring(message), 2) .. "\n")
  io.stderr:flush()
  os.exit(1, true)
end

local function assert_equal(expected, actual, label)
  assert(vim.deep_equal(expected, actual),
    ("%s: expected %s, got %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  print("PASS: " .. label)
end

local ready = vim.wait(20 * 60 * 1000, function()
  return vim.g.dotfiles_treesitter_ready == true or vim.g.dotfiles_treesitter_error ~= nil
end, 100)
assert(ready, "Mason did not finish installing tree-sitter-cli and the configured parsers")
assert(vim.g.dotfiles_treesitter_error == nil,
  "Treesitter installation failed: " .. tostring(vim.g.dotfiles_treesitter_error))

local executable = vim.fn.exepath("tree-sitter")
assert(executable ~= "", "tree-sitter-cli is not available in Neovim's PATH")
local version = vim.system({ executable, "--version" }, { text = true }):wait()
assert(version.code == 0, "tree-sitter --version failed: " .. tostring(version.stderr))
local major, minor, patch = (version.stdout or ""):match("(%d+)%.(%d+)%.(%d+)")
assert(major, "Could not parse tree-sitter-cli version: " .. tostring(version.stdout))
local version_number = tonumber(major) * 1000000 + tonumber(minor) * 1000 + tonumber(patch)
assert(version_number >= 26001,
  "tree-sitter-cli 0.26.1 or newer is required: " .. vim.trim(version.stdout))
print("PASS: Mason provides " .. vim.trim(version.stdout))

local fixtures = {
  {
    filetype = "javascript",
    extension = ".js",
    language = "javascript",
    source = { "function build() {", "return { enabled: true }", "}" },
  },
  {
    filetype = "javascriptreact",
    extension = ".jsx",
    language = "javascript",
    source = { "export default function View() {", "return <div><span>ok</span></div>", "}" },
  },
  {
    filetype = "typescript",
    extension = ".ts",
    language = "typescript",
    source = { "interface Settings {", "enabled: boolean", "}", "const settings: Settings = { enabled: true }" },
  },
  {
    filetype = "typescriptreact",
    extension = ".tsx",
    language = "tsx",
    source = { "type Props = { value: string }", "export function View(props: Props) {", "return <div>{props.value}</div>", "}" },
  },
  {
    filetype = "lua",
    extension = ".lua",
    language = "lua",
    source = { "local config = {", "  enabled = true,", "}" },
  },
  {
    filetype = "json",
    extension = ".json",
    language = "json",
    source = { "{", '  "enabled": true', "}" },
  },
  {
    filetype = "yaml",
    extension = ".yaml",
    language = "yaml",
    source = { "service:", "  enabled: true" },
  },
}

local temp_files = {}
local function open_fixture(fixture)
  local filename = vim.fn.tempname() .. fixture.extension
  temp_files[#temp_files + 1] = filename
  assert(vim.fn.writefile(fixture.source, filename) == 0,
    "Could not write " .. fixture.filetype .. " fixture")
  vim.cmd("enew!")
  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  assert_equal(fixture.filetype, vim.bo.filetype, fixture.filetype .. " filetype detection")
  assert_equal("v:lua.require'nvim-treesitter'.indentexpr()", vim.bo.indentexpr,
    fixture.filetype .. " uses the current Treesitter indentexpr")

  local parser = vim.treesitter.get_parser(0)
  assert_equal(fixture.language, parser:lang(), fixture.filetype .. " parser mapping")
  parser:parse()
  assert(vim.b.ts_highlight == true,
    fixture.filetype .. " buffer did not activate Neovim's Treesitter highlighter")
  print("PASS: " .. fixture.filetype .. " parsed and highlighted with " .. fixture.language)
  return filename
end

for _, fixture in ipairs(fixtures) do
  open_fixture(fixture)
end

-- Exercise Neovim's native incremental selection through the configured keys.
local selection_file = vim.fn.tempname() .. ".lua"
temp_files[#temp_files + 1] = selection_file
assert(vim.fn.writefile({ "local value = { nested = true }" }, selection_file) == 0)
vim.cmd("enew!")
vim.cmd("edit " .. vim.fn.fnameescape(selection_file))
vim.api.nvim_win_set_cursor(0, { 1, 18 })

local function selection_range()
  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  local a = { anchor[2], anchor[3] }
  local b = { cursor[2], cursor[3] }
  if a[1] > b[1] or (a[1] == b[1] and a[2] > b[2]) then
    a, b = b, a
  end
  return { a[1], a[2], b[1], b[2] }
end

local function wait_for_visual(label)
  assert(vim.wait(2000, function()
    return vim.fn.mode():sub(1, 1) == "v"
  end, 10), label .. " did not enter characterwise Visual mode (mode=" .. vim.fn.mode() .. ")")
end

assert(vim.api.nvim_input(" V") > 0, "Could not queue the <leader>V selection mapping")
wait_for_visual("Initial Treesitter selection")
local first = selection_range()

assert(vim.api.nvim_input(" V") > 0, "Could not queue the parent-selection mapping")
wait_for_visual("Parent-node expansion")
local parent = selection_range()
assert(parent[1] < first[1] or parent[2] < first[2]
    or parent[3] > first[3] or parent[4] > first[4],
  ("<leader>V did not expand the selection: first=%s parent=%s"):format(vim.inspect(first), vim.inspect(parent)))
print("PASS: <leader>V expands the native Treesitter parent selection")

assert(vim.api.nvim_input("<BS>") > 0, "Could not queue the child-selection mapping")
wait_for_visual("Child-node contraction")
local child = selection_range()
assert(child[1] > parent[1] or child[2] > parent[2]
    or child[3] < parent[3] or child[4] < parent[4],
  ("<BS> did not contract the selection: parent=%s child=%s"):format(vim.inspect(parent), vim.inspect(child)))
print("PASS: <BS> contracts to the native Treesitter child selection")
vim.api.nvim_input("<Esc>")

-- nvim-ts-autotag is configured through its standalone API and must work for
-- HTML, JSX and TSX rather than relying on the removed configs extension.
local tag_fixtures = {
  { filetype = "html", extension = ".html" },
  { filetype = "javascriptreact", extension = ".jsx" },
  { filetype = "typescriptreact", extension = ".tsx" },
}

for _, fixture in ipairs(tag_fixtures) do
  local filename = vim.fn.tempname() .. fixture.extension
  temp_files[#temp_files + 1] = filename
  assert(vim.fn.writefile({ "" }, filename) == 0, "Could not write autotag fixture")
  vim.cmd("enew!")
  vim.cmd("edit " .. vim.fn.fnameescape(filename))
  assert_equal(fixture.filetype, vim.bo.filetype, fixture.filetype .. " autotag fixture filetype")
  assert(vim.api.nvim_input("i<div>") > 0, "Could not queue opening tag input")
  assert(vim.wait(3000, function()
    return vim.api.nvim_get_current_line() == "<div></div>"
  end, 10), fixture.filetype .. " did not auto-close the HTML tag; got "
    .. vim.inspect(vim.api.nvim_get_current_line()))
  vim.api.nvim_input("<Esc>")
  print("PASS: nvim-ts-autotag auto-closes tags in " .. fixture.filetype)
end

assert(vim.g.loaded_rainbow_delimiters == true,
  "rainbow-delimiters was not loaded by the existing indentline integration")
print("PASS: standalone rainbow-delimiters integration loaded")

for _, filename in ipairs(temp_files) do
  vim.fn.delete(filename)
end

print("PASS: current Treesitter API, parsers, indentexpr, highlighting, selection and tag integrations")
