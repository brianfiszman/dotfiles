-- Regression test for scope-aware indentation with S, o and O.
--
-- The mapped commands must reindent the source line before opening the native
-- edit line. Language fixtures use real filenames so filetype detection,
-- Treesitter attachment, and the configured indentexpr are all exercised.
-- Expected indentation is explicit; the output of "==" is never its own oracle.
--
-- Real input is queued with nvim_input() and asserted from deferred callbacks
-- after Neovim's main loop has processed it. This is a disposable headless
-- process: fail() exits non-zero immediately so a bad assertion cannot become
-- a CI timeout.

_G.DotfilesTestIndent = function()
  return 4
end

local temp_files = {}
local current_parser_language = "none"

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
  local cursor = vim.api.nvim_win_get_cursor(0)
  return ("nvim=%s filetype=%s parser=%s indentexpr=%s shiftwidth=%d foldclosed=%d "
      .. "mode=%s cursor=%s buffer=%s"):format(
    vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    vim.bo.filetype,
    current_parser_language,
    vim.bo.indentexpr,
    vim.fn.shiftwidth(),
    vim.fn.foldclosed(cursor[1]),
    vim.fn.mode(),
    vim.inspect(cursor),
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
    ("%s row expected %d, got %d (%s)"):format(
      description, expected_row, cursor[1], buffer_state()))
  assert(vim.fn.indent(cursor[1]) == expected_indent,
    ("%s indent expected %d, got %d (%s)"):format(
      description, expected_indent, vim.fn.indent(cursor[1]), buffer_state()))
  assert(cursor[2] == expected_indent,
    ("%s column expected %d, got %d (%s)"):format(
      description, expected_indent, cursor[2], buffer_state()))
  assert(line == string.rep(" ", expected_indent),
    ("%s empty line expected %s, got %s (%s)"):format(
      description, vim.inspect(string.rep(" ", expected_indent)), vim.inspect(line), buffer_state()))
  print(("[indented-substitute] %s: row=%d column=%d indent=%d"):format(
    description, cursor[1], cursor[2], vim.fn.indent(cursor[1])))
end

local function set_buffer(lines, cursor)
  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.filetype = ""
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.softtabstop = 2
  vim.bo.tabstop = 2
  vim.bo.autoindent = true
  vim.bo.smartindent = false
  -- Fixtures stay unfolded so indentation assertions are about the mapping.
  -- The closed-fold control opts back into folding explicitly.
  vim.wo.foldenable = false
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
  current_parser_language = "none"
  assert(vim.fn.foldclosed(cursor[1]) == -1,
    "fixture must not hide the source line in a closed fold (" .. buffer_state() .. ")")
end

local parser_fixtures = {
  lua = { extension = ".lua", parser = "lua" },
  javascript = { extension = ".js", parser = "javascript" },
  javascriptreact = { extension = ".jsx", parser = "javascript" },
  typescript = { extension = ".ts", parser = "typescript" },
  typescriptreact = { extension = ".tsx", parser = "tsx" },
  json = { extension = ".json", parser = "json" },
  yaml = { extension = ".yaml", parser = "yaml" },
}

local function treesitter_fixture(filetype, lines, cursor)
  local spec = assert(parser_fixtures[filetype], "missing parser fixture for " .. filetype)
  local path = vim.fn.tempname() .. spec.extension
  temp_files[#temp_files + 1] = path
  assert(vim.fn.writefile(lines, path) == 0, "could not write " .. filetype .. " fixture")
  vim.cmd("enew!")
  vim.cmd("edit " .. vim.fn.fnameescape(path))

  -- Apply deterministic indentation dimensions after real FileType autocommands.
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.softtabstop = 2
  vim.bo.tabstop = 2
  vim.bo.autoindent = true
  vim.bo.smartindent = false
  vim.wo.foldenable = false

  assert(vim.bo.filetype == filetype,
    "filename-based filetype expected " .. filetype .. ", got " .. vim.inspect(vim.bo.filetype)
      .. " (" .. buffer_state() .. ")")
  assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
    filetype .. " must use configured Treesitter indentexpr (" .. buffer_state() .. ")")
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  assert(ok and parser ~= nil,
    filetype .. " Treesitter parser must be available: " .. vim.inspect(parser))
  current_parser_language = parser:lang()
  assert(current_parser_language == spec.parser,
    filetype .. " parser expected " .. spec.parser .. ", got " .. current_parser_language
      .. " (" .. buffer_state() .. ")")
  parser:parse()
  vim.api.nvim_win_set_cursor(0, cursor)
  assert(vim.fn.foldclosed(cursor[1]) == -1,
    "fixture must not hide source line in a closed fold (" .. buffer_state() .. ")")
  print(("[indented-substitute] fixture: filetype=%s parser=%s indentexpr=%s shiftwidth=%d"):format(
    filetype, current_parser_language, vim.bo.indentexpr, vim.fn.shiftwidth()))
end

local assert_source_reindented

local home_react_source = {
  'import { Fragment } from "react";',
  "import {",
  "  RouterLink,",
  "  Link,",
  "  Countdown,",
  "  Picture,",
  "  Title,",
  "  MainBody,",
  "  MainHeader,",
  '} from "../../components";',
  'import { theme } from "../../style/theme.style";',
  'import { startOfDay } from "date-fns";',
  'import chaufoPic from "../../resources/img/chaufo.png";',
  'import "./Home.css";',
  "",
  "function Home() {",
  "  const timeForChaufo = startOfDay(new Date(2023, 8, 30));",
  "",
  "  return (",
  "    <Fragment>",
  "      <MainHeader theme={theme}>",
  "        <Picture",
  "          src={chaufoPic}",
  '          alt="chaufo"',
  '          size="small"',
  '          borderRadius="4rem"',
  "        />",
  "      </MainHeader>",
  "",
  "      <MainBody theme={theme}>",
  "        {Date.now() < timeForChaufo ? (",
  '          <Title theme={theme}>En honor a Chaufo</Title>',
  "        ) : (",
  '          ""',
  "        )}",
  "",
  "        <Countdown countdownTo={timeForChaufo} theme={theme}>",
  "          <MainBody theme={theme}>",
  '            <Title theme={theme}>Timbre de Chaufo</Title>',
  "",
  '            <Link theme={theme} href="https://www.instagram.com/chaufoman/">',
  "              Learn about Chaufo",
  "            </Link>",
  "",
  '            <RouterLink to={"top10"} theme={theme}>',
  "              Top 7 de cosas con las que Chaufo nos ha divertido :-D",
  "            </RouterLink>",
  "",
  '            <RouterLink to={"chaufest"} theme={theme}>',
  "              Conocé todo sobre la Chaufest!",
  "            </RouterLink>",
  "          </MainBody>",
  "        </Countdown>",
  "      </MainBody>",
  "    </Fragment>",
  "  );",
  "}",
  "",
  "export default Home;",
}

local function home_react_case(filetype, target_fragment, key, source_indent, insert_indent, next_case)
  local lines = vim.deepcopy(home_react_source)
  local target_row
  for row, line in ipairs(lines) do
    if line:find(target_fragment, 1, true) then
      target_row = row
      break
    end
  end
  assert(target_row, "Home React fixture is missing target line " .. target_fragment)

  treesitter_fixture(filetype, lines, { target_row, 0 })
  local source_line = vim.api.nvim_buf_get_lines(0, target_row - 1, target_row, false)[1]
  local source_text = source_line:gsub("^%s+", "")
  assert(source_text:find(target_fragment, 1, true),
    "Home React target changed unexpectedly (" .. buffer_state() .. ")")
  vim.api.nvim_buf_set_lines(0, target_row - 1, target_row, false, { source_text })
  vim.treesitter.get_parser(0):parse()
  vim.api.nvim_win_set_cursor(0, { target_row, 0 })
  assert(vim.fn.indent(target_row) == 0,
    "Home React target must start with stale zero indentation (" .. buffer_state() .. ")")

  press(key, "Home React " .. filetype .. " " .. key .. " " .. target_fragment, function()
    local inserted_row = key == "o" and target_row + 1 or target_row
    assert_insert(inserted_row, insert_indent, "Home React " .. filetype .. " " .. key
      .. " " .. target_fragment)
    if key == "o" then
      assert_source_reindented(target_row, source_indent, source_text, "Home React " .. key)
    elseif key == "O" then
      assert_source_reindented(target_row + 1, source_indent, source_text, "Home React " .. key)
    end
    leave_insert("Home React " .. filetype .. " " .. key, next_case)
  end)
end

local function assert_stale_source(row, expected_text, description)
  local actual = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  assert(actual == expected_text,
    ("%s fixture text expected %s, got %s (%s)"):format(
      description, vim.inspect(expected_text), vim.inspect(actual), buffer_state()))
  assert(vim.fn.indent(row) == 0,
    ("%s fixture must start with stale zero indentation, got %d (%s)"):format(
      description, vim.fn.indent(row), buffer_state()))
end

assert_source_reindented = function(row, expected_indent, original_text, description)
  local expected = string.rep(" ", expected_indent) .. original_text
  local actual = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  assert(vim.fn.indent(row) == expected_indent,
    ("%s source indent expected %d, got %d (%s)"):format(
      description, expected_indent, vim.fn.indent(row), buffer_state()))
  assert(actual == expected,
    ("%s source line expected %s, got %s (%s)"):format(
      description, vim.inspect(expected), vim.inspect(actual), buffer_state()))
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
  for _, path in ipairs(temp_files) do
    vim.fn.delete(path)
  end
  print("PASS: deterministic S, o, O and counted 2S use the expected indentation")
  print("PASS: real Lua Treesitter indentation survives S")
  print("PASS: real TypeScript object-literal indentation supports o and O")
  print("PASS: real JavaScript block/object indentation supports S, o and O")
  print("PASS: simple JSX and TSX open-line indentation uses their configured parsers")
  print("PASS: the supplied Home React component preserves S, o and O in JS, JSX and TSX")
  print("PASS: real TypeScript interface/block/object indentation supports S, o and O")
  print("PASS: real JSON and YAML parsers preserve nested open-line indentation")
  print("PASS: a closed fold keeps native o at the fold boundary and hides the source")
  os.exit(0, true)
end

local run_yaml_control
local run_json_control
local run_javascript_substitute
local run_javascript_open_below
local run_javascript_open_above
local run_typescript_substitute
local run_typescript_nested_open_below
local run_typescript_nested_open_above
local run_typescript_open_above
local run_jsx_open_below
local run_tsx_open_below
local run_home_js_open_below
local run_home_js_substitute
local run_home_js_open_above
local run_home_jsx_open_below
local run_home_jsx_substitute
local run_home_jsx_open_above
local run_home_tsx_open_below
local run_home_tsx_substitute
local run_home_tsx_open_above

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
      "closed-fold o must not reindent the hidden source line (" .. buffer_state() .. ")")
    assert(vim.fn.foldclosed(2) ~= -1,
      "closed-fold o must leave the fold closed (" .. buffer_state() .. ")")
    leave_insert("closed-fold o", finish)
  end)
end

run_home_tsx_open_above = function()
  home_react_case("typescriptreact", "<Countdown countdownTo=", "O", 8, 8, run_home_js_open_below)
end

run_home_js_open_above = function()
  home_react_case("javascript", "<Countdown countdownTo=", "O", 8, 8, run_closed_fold_control)
end

run_home_js_substitute = function()
  home_react_case("javascript", "<Picture", "S", 8, 8, run_home_js_open_above)
end

run_home_js_open_below = function()
  home_react_case("javascript", "<MainHeader theme=", "o", 6, 8, run_home_js_substitute)
end

run_home_tsx_substitute = function()
  home_react_case("typescriptreact", "<Picture", "S", 8, 8, run_home_tsx_open_above)
end

run_home_tsx_open_below = function()
  home_react_case("typescriptreact", "<MainHeader theme=", "o", 6, 8, run_home_tsx_substitute)
end

run_home_jsx_open_above = function()
  home_react_case("javascriptreact", "<Countdown countdownTo=", "O", 8, 8, run_home_tsx_open_below)
end

run_home_jsx_substitute = function()
  home_react_case("javascriptreact", "<Picture", "S", 8, 8, run_home_jsx_open_above)
end

run_home_jsx_open_below = function()
  home_react_case("javascriptreact", "<MainHeader theme=", "o", 6, 8, run_home_jsx_substitute)
end

run_tsx_open_below = function()
  treesitter_fixture("typescriptreact", {
    "export default function Home() {",
    "return (",
    "<>",
    "<Button",
    "style={{",
    "color: 'blue',",
    "}}",
    "/>",
    "</>",
    ")",
    "}",
  }, { 4, 0 })
  assert_stale_source(4, "<Button", "TSX component opening")
  press("o", "TSX component o", function()
    assert_insert(5, 8, "TSX component o")
    assert_source_reindented(4, 6, "<Button", "TSX component o")
    leave_insert("TSX component o", run_home_jsx_open_below)
  end)
end

run_jsx_open_below = function()
  treesitter_fixture("javascriptreact", {
    "export default function Home() {",
    "return (",
    "<>",
    "<Button",
    "style={{",
    "color: 'blue',",
    "}}",
    "/>",
    "</>",
    ")",
    "}",
  }, { 4, 0 })
  assert_stale_source(4, "<Button", "JSX component opening")
  press("o", "JSX component o", function()
    assert_insert(5, 8, "JSX component o")
    assert_source_reindented(4, 6, "<Button", "JSX component o")
    leave_insert("JSX component o", run_tsx_open_below)
  end)
end

run_json_control = function()
  treesitter_fixture("json", {
    "{",
    '"options": {',
    '"enabled": true',
    "}",
    "}",
  }, { 2, 0 })
  assert_stale_source(2, '"options": {', "JSON nested object")
  press("o", "JSON nested o", function()
    assert_insert(3, 4, "JSON nested o")
    assert_source_reindented(2, 2, '"options": {', "JSON nested o")
    leave_insert("JSON nested o", run_jsx_open_below)
  end)
end

run_yaml_control = function()
  treesitter_fixture("yaml", {
    "service:",
    "  enabled: true",
  }, { 2, 0 })
  press("o", "YAML nested o", function()
    assert_insert(3, 2, "YAML nested o")
    assert_source_reindented(2, 2, "enabled: true", "YAML nested o")
    leave_insert("YAML nested o", run_json_control)
  end)
end

run_typescript_nested_open_above = function()
  treesitter_fixture("typescript", {
    "export function build() {",
    "return {",
    "enabled: true,",
    "};",
    "}",
  }, { 3, 0 })
  assert_stale_source(3, "enabled: true,", "TypeScript nested object O")
  press("O", "TypeScript nested O", function()
    assert_insert(3, 4, "TypeScript nested O")
    assert_source_reindented(4, 4, "enabled: true,", "TypeScript nested O")
    leave_insert("TypeScript nested O", run_yaml_control)
  end)
end

run_typescript_nested_open_below = function()
  treesitter_fixture("typescript", {
    "export function build() {",
    "return {",
    "enabled: true,",
    "};",
    "}",
  }, { 2, 0 })
  assert_stale_source(2, "return {", "TypeScript nested object o")
  press("o", "TypeScript nested o", function()
    assert_insert(3, 4, "TypeScript nested o")
    assert_source_reindented(2, 2, "return {", "TypeScript nested o")
    leave_insert("TypeScript nested o", run_typescript_nested_open_above)
  end)
end

run_typescript_substitute = function()
  treesitter_fixture("typescript", {
    "interface Settings {",
    "enabled: boolean;",
    "}",
  }, { 2, 0 })
  assert_stale_source(2, "enabled: boolean;", "TypeScript interface S")
  press("S", "TypeScript interface S", function()
    assert_insert(2, 2, "TypeScript interface S")
    leave_insert("TypeScript interface S", run_typescript_nested_open_below)
  end)
end

run_typescript_open_above = function()
  treesitter_fixture("typescript", {
    "const options = {",
    "enabled: true,",
    "};",
  }, { 2, 0 })
  assert_stale_source(2, "enabled: true,", "TypeScript object O")
  press("O", "TypeScript object O", function()
    assert_insert(2, 2, "TypeScript object O")
    assert_source_reindented(3, 2, "enabled: true,", "TypeScript object O")
    leave_insert("TypeScript object O", run_javascript_substitute)
  end)
end

run_javascript_open_above = function()
  treesitter_fixture("javascript", {
    "function build() {",
    "if (true) {",
    "return true;",
    "}",
    "}",
  }, { 3, 0 })
  assert_stale_source(3, "return true;", "JavaScript nested block O")
  press("O", "JavaScript nested block O", function()
    assert_insert(3, 4, "JavaScript nested block O")
    assert_source_reindented(4, 4, "return true;", "JavaScript nested block O")
    leave_insert("JavaScript nested block O", run_typescript_substitute)
  end)
end

run_javascript_open_below = function()
  treesitter_fixture("javascript", {
    "function build() {",
    "return {",
    "enabled: true,",
    "};",
    "}",
  }, { 2, 0 })
  assert_stale_source(2, "return {", "JavaScript nested object o")
  press("o", "JavaScript nested object o", function()
    assert_insert(3, 4, "JavaScript nested object o")
    assert_source_reindented(2, 2, "return {", "JavaScript nested object o")
    leave_insert("JavaScript nested object o", run_javascript_open_above)
  end)
end

run_javascript_substitute = function()
  treesitter_fixture("javascript", {
    "function build() {",
    "return true;",
    "}",
  }, { 2, 0 })
  assert_stale_source(2, "return true;", "JavaScript block S")
  press("S", "JavaScript block S", function()
    assert_insert(2, 2, "JavaScript block S")
    leave_insert("JavaScript block S", run_javascript_open_below)
  end)
end

local function run_lua_substitute()
  treesitter_fixture("lua", {
    "local options = {",
    "enabled = true,",
    "}",
  }, { 2, 0 })
  -- This fixture intentionally retains the original Lua parser coverage.
  assert(vim.fn.indent(2) == 0, "Lua fixture must start with stale indentation (" .. buffer_state() .. ")")
  press("S", "Lua S", function()
    assert_insert(2, 2, "Lua S")
    leave_insert("Lua S", run_typescript_open_above)
  end)
end

local function run_counted_substitute()
  set_buffer({ "one", "two", "tail" }, { 1, 0 })
  vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"
  press("2S", "2S", function()
    assert(vim.api.nvim_buf_line_count(0) == 2,
      "2S must replace exactly two lines with one (" .. buffer_state() .. ")")
    assert_insert(1, 4, "2S")
    leave_insert("2S", run_lua_substitute)
  end)
end

local function run_open_above()
  set_buffer({ "head", "stale" }, { 2, 0 })
  vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"
  press("O", "O", function()
    assert_insert(2, 4, "O")
    leave_insert("O", run_counted_substitute)
  end)
end

local function run_open_below()
  set_buffer({ "stale", "tail" }, { 1, 0 })
  vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"
  press("o", "o", function()
    assert_insert(2, 4, "o")
    leave_insert("o", run_open_above)
  end)
end

local function run_deterministic_substitute()
  set_buffer({ "stale", "tail" }, { 1, 0 })
  vim.bo.indentexpr = "v:lua.DotfilesTestIndent()"
  press("S", "S", function()
    assert_insert(1, 4, "S")
    leave_insert("S", run_open_below)
  end)
end

local nvim_version = vim.version()
local lockfile_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
local lockfile_lines = vim.fn.readfile(lockfile_path)
local lockfile = vim.json.decode(table.concat(lockfile_lines, "\n"))
local treesitter_lock = lockfile["nvim-treesitter"] and lockfile["nvim-treesitter"].commit or "unknown"
print(("[indented-substitute] environment: Neovim %d.%d.%d, nvim-treesitter=%s"):format(
  nvim_version.major, nvim_version.minor, nvim_version.patch, treesitter_lock))

vim.defer_fn(function()
  fail("indentation test sequence exceeded 60 seconds")
end, 60000)

run_deterministic_substitute()
