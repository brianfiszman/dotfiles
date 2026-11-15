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

local function wait_for_current_line_indent(expected, expected_row, description, callback)
  local deadline = vim.uv.hrtime() + 1500000000
  local function poll()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local actual_indent = vim.fn.indent(cursor[1])
    local line = vim.api.nvim_get_current_line()
    if vim.fn.mode():sub(1, 1) == "i"
      and cursor[1] == expected_row
      and cursor[2] == expected
      and actual_indent == expected
    then
      safely(callback)
    elseif vim.uv.hrtime() >= deadline then
      fail(("%s indentation did not settle (mode=%s row=%d column=%d indent=%d line=%s buffer=%s)"):format(
        description, vim.fn.mode(), cursor[1], cursor[2], actual_indent, vim.inspect(line),
        vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
    else
      vim.defer_fn(poll, 10)
    end
  end
  vim.defer_fn(poll, 10)
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

local function probe_named_on_key_handlers()
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
  vim.bo.indentexpr = ""
  vim.bo.indentkeys = ""
  vim.bo.formatoptions = ""
  vim.bo.comments = ""
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.cindent = false
  vim.bo.lisp = false
  vim.api.nvim_win_set_cursor(0, { 2, 0 })

  local callbacks_before = vim.on_key()
  local namespaces = vim.api.nvim_get_namespaces()
  local removed = {}
  for name, ns_id in pairs(namespaces) do
    vim.on_key(nil, ns_id)
    removed[#removed + 1] = name
  end
  local callbacks_after = vim.on_key()
  print(("[scope-indent-on-key] callbacks before=%d after_named_clear=%d named_namespaces=%s"):format(
    callbacks_before, callbacks_after, vim.inspect(removed)))

  vim.cmd("noautocmd normal! o")
  print(("[scope-indent-on-key] after named callback clear cursor=%s line_count=%d buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
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
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "FileType" })) do
    local pattern = autocmd.pattern or ""
    if pattern == "*" or pattern == "" or pattern:find("typescript", 1, true) then
      print(("[scope-indent-filetype] group=%s id=%s pattern=%q desc=%q command=%q callback=%s buffer=%s"):format(
        tostring(autocmd.group_name or autocmd.group),
        tostring(autocmd.group), pattern, tostring(autocmd.desc),
        tostring(autocmd.command), type(autocmd.callback),
        tostring(autocmd.buffer)))
    end
  end
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

local function scope_indent_local_options()
  return {
    buftype = vim.bo.buftype,
    filetype = vim.bo.filetype,
    autoindent = vim.bo.autoindent,
    smartindent = vim.bo.smartindent,
    cindent = vim.bo.cindent,
    lisp = vim.bo.lisp,
    expandtab = vim.bo.expandtab,
    copyindent = vim.bo.copyindent,
    preserveindent = vim.bo.preserveindent,
    smarttab = vim.o.smarttab,
    shiftwidth = vim.bo.shiftwidth,
    softtabstop = vim.bo.softtabstop,
    tabstop = vim.bo.tabstop,
    formatoptions = vim.bo.formatoptions,
    comments = vim.bo.comments,
    commentstring = vim.bo.commentstring,
    indentexpr = vim.bo.indentexpr,
    indentkeys = vim.bo.indentkeys,
    cinkeys = vim.bo.cinkeys,
    cinoptions = vim.bo.cinoptions,
    lispwords = vim.bo.lispwords,
    formatexpr = vim.bo.formatexpr,
    equalprg = vim.bo.equalprg,
    omnifunc = vim.bo.omnifunc,
    complete = vim.bo.complete,
    virtualedit = vim.wo.virtualedit,
    whichwrap = vim.o.whichwrap,
  }
end

local function probe_native_typescript_open(label, formatoptions, indentexpr, keys, clear_filetype)
  setup_typescript_buffer()
  if clear_filetype then
    vim.bo.filetype = ""
  end
  vim.bo.formatoptions = formatoptions
  vim.bo.indentexpr = indentexpr
  local before = {
    cursor = vim.api.nvim_win_get_cursor(0),
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
  }
  print(("[scope-indent-probe] before %s cursor=%s line_count=%d options=%s"):format(
    label, vim.inspect(before.cursor), #before.lines,
    vim.inspect(scope_indent_local_options())))
  vim.cmd.normal({ args = { keys }, bang = true })
  local after_cursor = vim.api.nvim_win_get_cursor(0)
  local after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print(("[scope-indent-probe] after %s cursor=%s line_count=%d mode=%s buffer=%s"):format(
    label, vim.inspect(after_cursor), #after_lines, vim.fn.mode(),
    vim.inspect(after_lines)))
end

local function probe_typescript_without_parser()
  setup_typescript_buffer()
  vim.bo.indentexpr = ""
  vim.bo.formatoptions = ""
  local parser = vim.treesitter.get_parser(0, "typescript")
  print(("[scope-indent-probe] before stop parser attached=%s cursor=%s line_count=%d"):format(
    tostring(parser ~= nil), vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0)))
  vim.treesitter.stop(0)
  print(("[scope-indent-probe] after stop parser=%s cursor=%s line_count=%d indentexpr=%q"):format(
    tostring(pcall(vim.treesitter.get_parser, 0, "typescript")),
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0), vim.bo.indentexpr))
  vim.cmd.normal({ args = { "o" }, bang = true })
  print(("[scope-indent-probe] after native o with TS filetype and parser stopped cursor=%s line_count=%d buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_javascript_filetype()
  setup_typescript_buffer()
  vim.bo.filetype = "javascript"
  vim.bo.indentexpr = ""
  vim.bo.formatoptions = ""
  vim.cmd.normal({ args = { "o" }, bang = true })
  print(("[scope-indent-probe] after native o javascript filetype cursor=%s line_count=%d options=%s buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0),
    vim.inspect(scope_indent_local_options()),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_feedkeys_native_open()
  setup_typescript_buffer()
  vim.bo.indentexpr = ""
  print(("[scope-indent-probe] before feedkeys native o filetype=%q cursor=%s line_count=%d formatoptions=%q"):format(
    vim.bo.filetype, vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0), vim.bo.formatoptions))
  local keys = vim.api.nvim_replace_termcodes("o", true, false, true)
  vim.api.nvim_feedkeys(keys, "ntx", false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print(("[scope-indent-probe] after feedkeys native o cursor=%s line_count=%d mode=%s buffer=%s"):format(
    vim.inspect(cursor), #lines, vim.fn.mode(), vim.inspect(lines)))
end

local function probe_filetype_handler_groups()
  local handlers = vim.api.nvim_get_autocmds({ event = "FileType" })
  local candidates = {
    "ts_context_commentstring",
    "NvimTreesitter-highlight",
    "NvimTreesitter-incremental_selection",
    "NvimTreesitter-indent",
    "_luasnip_lazy_load",
    "ColorizerSetup",
    "nvim.lsp.enable",
    "NvimTreesitter-autotag",
    "autopairs_buf",
  }

  local function open_with_current_handlers(label)
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
    vim.bo.indentexpr = ""
    vim.bo.indentkeys = ""
    vim.bo.formatoptions = ""
    vim.bo.comments = ""
    vim.bo.commentstring = ""
    vim.bo.autoindent = false
    vim.bo.smartindent = false
    vim.bo.cindent = false
    vim.bo.lisp = false
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("noautocmd normal! o")
    local cursor = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    print(("[scope-indent-group-probe] %s cursor=%s line_count=%d buffer=%s"):format(
      label, vim.inspect(cursor), #lines, vim.inspect(lines)))
    return cursor[1]
  end

  open_with_current_handlers("all FileType handlers enabled")
  local function restore_autocmd(autocmd)
    local opts = {
      group = autocmd.group,
      pattern = autocmd.pattern,
    }
    if autocmd.buffer and autocmd.buffer > 0 then
      opts.buffer = autocmd.buffer
      opts.pattern = nil
    end
    if autocmd.desc then
      opts.desc = autocmd.desc
    end
    if autocmd.once then
      opts.once = true
    end
    if autocmd.nested then
      opts.nested = true
    end
    if autocmd.callback then
      opts.callback = autocmd.callback
    elseif autocmd.command and autocmd.command ~= "" then
      opts.command = autocmd.command
    end
    vim.api.nvim_create_autocmd(autocmd.event, opts)
  end

  local function run_with_only_groups(label, enabled_groups)
    local removed = {}
    local current_handlers = vim.api.nvim_get_autocmds({ event = "FileType" })
    local keep_native = {
      filetypeplugin = true,
      filetypeindent = true,
      syntaxset = true,
    }
    for _, autocmd in ipairs(current_handlers) do
      local keep = keep_native[autocmd.group_name] or enabled_groups[autocmd.group_name]
      if not keep and autocmd.id then
        vim.api.nvim_del_autocmd(autocmd.id)
        removed[#removed + 1] = autocmd
      end
    end
    local row = open_with_current_handlers(label .. " removed=" .. #removed)
    for _, autocmd in ipairs(removed) do
      restore_autocmd(autocmd)
    end
    return row
  end

  local only_native_row = run_with_only_groups("only native filetype handlers", {})
  for _, candidate in ipairs(candidates) do
    run_with_only_groups("only " .. candidate, { [candidate] = true })
  end
  print("[scope-indent-group-probe] only-native-row=" .. only_native_row)
end

local function probe_typescript_without_filetype_scripts()
  local runtime_patterns = {
    "ftplugin/typescript*",
    "after/ftplugin/typescript*",
    "indent/typescript*",
    "after/indent/typescript*",
  }
  for _, pattern in ipairs(runtime_patterns) do
    for _, filename in ipairs(vim.fn.globpath(vim.o.runtimepath, pattern, 0, 1)) do
      print(("[scope-indent-runtime] pattern=%q file=%q"):format(pattern, filename))
    end
  end

  vim.cmd("enew!")
  vim.bo.buftype = ""
  vim.bo.bufhidden = "wipe"
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.b.did_ftplugin = 1
  vim.b.did_indent = 1
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "const options = {",
    "enabled: true,",
    "};",
  })
  vim.cmd("setfiletype typescript")
  assert(vim.bo.filetype == "typescript",
    "TypeScript fixture with ftplugins skipped must keep its filetype")
  vim.bo.indentexpr = ""
  vim.bo.indentkeys = ""
  vim.bo.formatoptions = ""
  vim.bo.comments = ""
  vim.bo.commentstring = ""
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.cindent = false
  vim.bo.lisp = false
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  print(("[scope-indent-runtime] skipped ftplugin=%s indent=%s options=%s"):format(
    tostring(vim.b.did_ftplugin), tostring(vim.b.did_indent),
    vim.inspect(scope_indent_local_options())))
  vim.cmd("noautocmd normal! o")
  print(("[scope-indent-runtime] after skip TS scripts cursor=%s buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_typescript_without_filetype_autocmds()
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
  vim.cmd("noautocmd setfiletype typescript")
  assert(vim.bo.filetype == "typescript",
    "noautocmd TypeScript fixture must still set its filetype")
  vim.bo.indentexpr = ""
  vim.bo.indentkeys = ""
  vim.bo.formatoptions = ""
  vim.bo.comments = ""
  vim.bo.commentstring = ""
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.cindent = false
  vim.bo.lisp = false
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  print(("[scope-indent-filetype] before noautocmd FileType handlers cursor=%s filetype=%q buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)), vim.bo.filetype,
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
  vim.cmd("noautocmd normal! o")
  print(("[scope-indent-filetype] after noautocmd FileType handlers cursor=%s line_count=%d buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)), vim.api.nvim_buf_line_count(0),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_typescript_noautocmd_open()
  setup_typescript_buffer()
  vim.bo.indentexpr = ""
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.cindent = false
  vim.bo.lisp = false
  vim.bo.formatoptions = ""
  vim.bo.indentkeys = ""
  vim.bo.comments = ""
  local before = {
    cursor = vim.api.nvim_win_get_cursor(0),
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false),
  }
  print(("[scope-indent-probe] before noautocmd typescript o cursor=%s lines=%s options=%s"):format(
    vim.inspect(before.cursor), vim.inspect(before.lines),
    vim.inspect(scope_indent_local_options())))
  vim.cmd("noautocmd normal! o")
  print(("[scope-indent-probe] after noautocmd typescript o cursor=%s line_count=%d mode=%s buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0), vim.fn.mode(),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_typescript_indentkeys_disabled()
  setup_typescript_buffer()
  vim.bo.indentexpr = ""
  vim.bo.indentkeys = ""
  vim.bo.formatoptions = ""
  local before = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ args = { "o" }, bang = true })
  print(("[scope-indent-probe] after TS indentkeys empty cursor=%s line_count=%d buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_typescript_autoindent_disabled()
  setup_typescript_buffer()
  vim.bo.indentexpr = ""
  vim.bo.autoindent = false
  vim.bo.smartindent = false
  vim.bo.cindent = false
  vim.bo.lisp = false
  vim.bo.formatoptions = ""
  local before = vim.api.nvim_win_get_cursor(0)
  vim.cmd.normal({ args = { "o" }, bang = true })
  print(("[scope-indent-probe] after TS indentation options disabled cursor=%s line_count=%d buffer=%s"):format(
    vim.inspect(vim.api.nvim_win_get_cursor(0)),
    vim.api.nvim_buf_line_count(0),
    vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false))))
end

local function probe_minimal_child_typescript_open(label, enable_filetype_indent, prime_with_equal, disable_indentexpr)
  local child_script = vim.fn.tempname() .. ".lua"
  local child_lines = {
    string.format('vim.cmd("filetype plugin indent %s")', enable_filetype_indent and "on" or "off"),
    'vim.cmd("enew")',
    'vim.api.nvim_buf_set_lines(0, 0, -1, false, { "const options = {", "enabled: true,", "};" })',
    'vim.cmd("setfiletype typescript")',
    'vim.api.nvim_win_set_cursor(0, { 2, 0 })',
    prime_with_equal and 'vim.cmd("normal! ==")' or '-- skip source reindent',
    prime_with_equal and 'vim.api.nvim_buf_set_lines(0, 1, 2, false, { "enabled: true," })' or '-- keep source as-is',
    prime_with_equal and 'vim.api.nvim_win_set_cursor(0, { 2, 0 })' or '-- keep cursor as-is',
    disable_indentexpr and 'vim.bo.indentexpr = ""' or '-- keep active indentexpr',
    'local before = vim.api.nvim_win_get_cursor(0)',
    'print("[scope-indent-child] " .. "primed=" .. tostring(' .. tostring(prime_with_equal) .. ') .. " before o=" .. vim.inspect(before) .. " source=" .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)))',
    'vim.cmd.normal({ args = { "o" }, bang = true })',
    'print("[scope-indent-child] ' .. label .. ' before=" .. vim.inspect(before) .. " after=" .. vim.inspect(vim.api.nvim_win_get_cursor(0)) .. " lines=" .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)) .. " indentexpr=" .. vim.inspect(vim.bo.indentexpr))',
    'vim.cmd("qa!")',
  }
  vim.fn.writefile(child_lines, child_script)
  local output = vim.fn.system({
    vim.v.progpath,
    "--headless",
    "-u",
    "NONE",
    "-l",
    child_script,
  })
  local exit_code = vim.v.shell_error
  vim.fn.delete(child_script)
  local output_text = tostring(output):gsub("\\n", " | ")
  print(("[scope-indent-child] %s exit=%d output=%s"):format(
    label, exit_code, vim.inspect(output_text)))
  assert(exit_code == 0, "minimal child Neovim probe failed: " .. output)
end

local function probe_minimal_neovim_runtime()
  probe_minimal_child_typescript_open("minimal TS no-prime", true, false, false)
  probe_minimal_child_typescript_open("minimal TS runtime == then clear indentexpr", true, true, true)
  probe_minimal_child_typescript_open("minimal TS runtime == keep indentexpr", true, true, false)
  probe_minimal_child_typescript_open("minimal TS indent plugin off", false, false, true)
end

local function probe_native_typescript_open_variants()
  probe_native_typescript_open("no-count, indentexpr disabled", "jcroql", "", "o")
  probe_native_typescript_open("count-one, indentexpr disabled", "jcroql", "", "1o")
  probe_native_typescript_open("no-count, formatoptions without o", "jcrql", "", "o")
  probe_native_typescript_open("no-count, formatoptions empty", "", "", "o")
  probe_native_typescript_open("no-count, Treesitter indentexpr active", "jcroql", "nvim_treesitter#indent()", "o")
  probe_native_typescript_open("no-count, no TypeScript filetype", "tcqj", "", "o", true)
  probe_typescript_without_parser()
  probe_javascript_filetype()
  probe_feedkeys_native_open()
  probe_typescript_noautocmd_open()
  probe_typescript_indentkeys_disabled()
  probe_typescript_autoindent_disabled()
  probe_minimal_neovim_runtime()
  probe_typescript_without_filetype_autocmds()
end

local function run_typescript_o()
  probe_typescript_without_filetype_scripts()
  probe_filetype_handler_groups()
  probe_native_typescript_open_variants()
  probe_named_on_key_handlers()
  local expected = setup_typescript_buffer()
  press("o", "i", "TypeScript o with Treesitter indentation", function()
    wait_for_current_line_indent(expected, 3, "TypeScript o with Treesitter indentation", function()
      assert_current_line_indent(expected, "TypeScript o with Treesitter indentation", 3)
      assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
        "TypeScript indentexpr must remain active")
      assert(vim.api.nvim_get_current_line() == string.rep(" ", expected),
        "TypeScript o must preserve the computed scope prefix")
      leave_insert("TypeScript o", function()
        run_typescript_O()
      end)
    end)
  end)
end

run_typescript_O = function()
  local expected = setup_typescript_buffer()
  press("O", "i", "TypeScript O with Treesitter indentation", function()
    wait_for_current_line_indent(expected, 2, "TypeScript O with Treesitter indentation", function()
      assert_current_line_indent(expected, "TypeScript O with Treesitter indentation", 2)
      assert(vim.bo.indentexpr == "nvim_treesitter#indent()",
        "TypeScript indentexpr must remain active")
      assert(vim.api.nvim_get_current_line() == string.rep(" ", expected),
        "TypeScript O must preserve the computed scope prefix")
      leave_insert("TypeScript O", finish)
    end)
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
    wait_for_current_line_indent(4, 2, "O", function()
      assert_current_line_indent(4, "O", 2)
      leave_insert("O", run_counted_substitute)
    end)
  end)
end

local function run_open_below()
  set_lines({ "outer", "tail" }, { 1, 0 })
  press("o", "i", "o", function()
    wait_for_current_line_indent(4, 2, "o", function()
      assert_current_line_indent(4, "o", 2)
      leave_insert("o", run_open_above)
    end)
  end)
end

set_lines({ "stale", "tail" }, { 1, 0 })
press("S", "i", "S", function()
  assert_current_line_indent(4, "S", 1)
  assert(vim.api.nvim_get_current_line() == "    ",
    "S must preserve the deterministic computed indentation")
  leave_insert("S", run_open_below)
end)
