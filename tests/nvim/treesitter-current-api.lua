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

local parser_languages = {
  "c", "lua", "luadoc", "go", "javascript", "typescript", "json", "json5", "jsdoc", "yaml",
  "xml", "vim", "vimdoc", "tsx", "scheme", "make", "dot", "dockerfile", "csv", "diff",
  "gitignore", "gitcommit", "git_config", "git_rebase", "gitattributes", "css", "comment",
  "gomod", "gosum", "gowork", "html", "ini", "markdown", "markdown_inline", "passwd",
  "proto", "scss", "sql", "regex", "bash", "helm",
}

local treesitter_plugin = require("lazy.core.config").plugins["nvim-treesitter"]
assert(treesitter_plugin and treesitter_plugin.branch == "main",
  "The current upstream nvim-treesitter main branch must be configured")

assert(require("lazy.core.config").plugins["lua-json5"] == nil,
  "The unused native lua-json5 Rust build dependency must not be restored")
print("PASS: JSON5 parser coverage does not require the native lua-json5 Rust module")

local treesitter = require("nvim-treesitter")
local installed = {}
for _, language in ipairs(treesitter.get_installed("parsers")) do
  installed[language] = true
end
for _, language in ipairs(parser_languages) do
  assert(installed[language], "Configured Treesitter parser was not installed: " .. language)
end
print(("PASS: all %d configured Treesitter parsers are installed"):format(#parser_languages))

local executable = vim.fn.exepath("tree-sitter")
assert(executable ~= "", "tree-sitter-cli is not available in Neovim's PATH")
local version = vim.system({ executable, "--version" }, { text = true }):wait()
assert(version.code == 0, "tree-sitter --version failed: " .. tostring(version.stderr))
local major, minor, patch = (version.stdout or ""):match("(%d+)%.(%d+)%.(%d+)")
assert(major, "Could not parse tree-sitter-cli version: " .. tostring(version.stdout))
local cli_version = table.concat({ major, minor, patch }, ".")
assert(cli_version == "0.27.2",
  "Mason must provide pinned tree-sitter-cli 0.27.2; found " .. vim.trim(version.stdout))
print("PASS: Mason provides pinned " .. vim.trim(version.stdout))

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
    filetype = "json5",
    extension = ".json5",
    language = "json5",
    expect_clean_parse = true,
    source = {
      "{",
      "  // JSON5 supports comments and unquoted keys",
      "  unquotedKey: 'single-quoted value',",
      "  trailingComma: true,",
      "}",
    },
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
  local indent_query_ok, indent_query = pcall(vim.treesitter.query.get, fixture.language, "indents")
  local has_indent_query = indent_query_ok and indent_query ~= nil
  if has_indent_query then
    assert_equal("v:lua.require'nvim-treesitter'.indentexpr()", vim.bo.indentexpr,
      fixture.filetype .. " uses the current Treesitter indentexpr")
  else
    assert(vim.bo.indentexpr ~= "v:lua.require'nvim-treesitter'.indentexpr()",
      fixture.filetype .. " must not enable Treesitter indentation without an indents.scm query")
    print("PASS: " .. fixture.filetype .. " retains its native indentexpr because no indents.scm query exists")
  end

  local parser = vim.treesitter.get_parser(0)
  assert_equal(fixture.language, parser:lang(), fixture.filetype .. " parser mapping")
  local trees = parser:parse()
  if fixture.expect_clean_parse then
    assert(#trees > 0, fixture.filetype .. " parser returned no syntax trees")
    assert_equal(false, trees[1]:root():has_error(),
      fixture.filetype .. " accepts JSON5-only syntax without parser errors")
  end
  local highlights_query_ok, highlights_query = pcall(vim.treesitter.query.get, fixture.language, "highlights")
  local has_highlights_query = highlights_query_ok and highlights_query ~= nil
  if has_highlights_query then
    assert_equal(true, vim.b.ts_highlight,
      fixture.filetype .. " activates Neovim's Treesitter highlighter when highlights.scm exists")
  else
    assert(vim.b.ts_highlight ~= true,
      fixture.filetype .. " must not mark Treesitter highlighting active without a highlights.scm query")
    print("PASS: " .. fixture.filetype .. " has no highlights.scm query; parser remains available without a highlighter")
  end
  assert(vim.bo.syntax == "ON",
    fixture.filetype .. " lost the legacy Vim regex highlighting layer")
  assert(vim.b.current_syntax ~= nil,
    fixture.filetype .. " did not load its Vim regex syntax definitions")
  print("PASS: " .. fixture.filetype .. " parsed with the available Treesitter and Vim syntax layers")
  return filename
end

for _, fixture in ipairs(fixtures) do
  open_fixture(fixture)
end

-- The old nvim-treesitter modules attached to every installed parser with
-- matching queries, not only the ensure_installed list. Keep that behavior for
-- parsers users install later through :TSInstall or another source.
assert(not vim.tbl_contains(parser_languages, "python"),
  "Python is intentionally outside the managed parser set for this regression test")
local python_installed = treesitter.install({ "python" }, { summary = true }):wait(5 * 60 * 1000)
assert(python_installed, "could not install the manually requested Python parser")
open_fixture({
  filetype = "python",
  extension = ".py",
  language = "python",
  source = { "def build():", "    return {", "        \"enabled\": True", "    }" },
})
print("PASS: a manually installed Python parser outside the managed list is configured")

-- Exercise Neovim's native incremental selection through the configured keys.
local function feed_keys(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  -- "m" honors user mappings, "t" behaves like typed input, and "x" drains
  -- the input queue before this assertion script continues.
  vim.api.nvim_feedkeys(termcodes, "mtx", false)
end

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

feed_keys(" V")
wait_for_visual("Initial Treesitter selection")
local first = selection_range()

feed_keys(" V")
wait_for_visual("Parent-node expansion")
local parent = selection_range()
assert(parent[1] < first[1] or parent[2] < first[2]
    or parent[3] > first[3] or parent[4] > first[4],
  ("<leader>V did not expand the selection: first=%s parent=%s"):format(vim.inspect(first), vim.inspect(parent)))
print("PASS: <leader>V expands the native Treesitter parent selection")

feed_keys("<BS>")
wait_for_visual("Child-node contraction")
local child = selection_range()
assert(child[1] > parent[1] or child[2] > parent[2]
    or child[3] < parent[3] or child[4] < parent[4],
  ("<BS> did not contract the selection: parent=%s child=%s"):format(vim.inspect(parent), vim.inspect(child)))
print("PASS: <BS> contracts to the native Treesitter child selection")
feed_keys("<Esc>")

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
  feed_keys("i<div>")
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
