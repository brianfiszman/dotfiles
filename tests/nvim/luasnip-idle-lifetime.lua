-- Exercise the configured LuaSnip + nvim-cmp key path and real CursorHold events.
-- Every scenario runs in the isolated headless Neovim process from the main suite.

local function resume_test(thread, ok, err)
  local resumed, resume_error = coroutine.resume(thread, ok, err)
  if not resumed then
    io.stderr:write("[luasnip-idle-lifetime] " .. debug.traceback(thread, tostring(resume_error)) .. "\\n")
    vim.cmd("cquit 1")
  end
end
local function feed(keys, after_input)
  local thread = coroutine.running()
  assert(thread, "real editor input must run from the test coroutine")
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  local accepted = vim.api.nvim_input(termcodes)
  assert(accepted == #termcodes,
    ("Neovim accepted %d/%d input bytes for %q"):format(accepted, #termcodes, keys))

  -- Yield the test coroutine. Neovim's main loop consumes the input before a
  -- later timer checks the editor state and resumes the scenario.
  vim.defer_fn(function()
    local ok, err = xpcall(function()
      if after_input then
        after_input()
      end
    end, debug.traceback)
    resume_test(thread, ok, err)
  end, 20)

  local ok, err = coroutine.yield()
  if not ok then
    error(err or ("Neovim input failed for " .. keys), 0)
  end
end

local function wait_until(predicate, timeout_ms, label)
  local thread = coroutine.running()
  assert(thread, "asynchronous waits must run from the test coroutine")
  local started_at = vim.uv.hrtime()

  local function poll()
    local ok, result = pcall(predicate)
    if not ok then
      resume_test(thread, false, result)
      return
    end
    if result then
      resume_test(thread, true)
      return
    end

    local elapsed_ms = (vim.uv.hrtime() - started_at) / 1000000
    if elapsed_ms >= timeout_ms then
      resume_test(thread, false, ("Timed out: %s after %dms"):format(label, timeout_ms))
      return
    end
    vim.defer_fn(poll, 20)
  end

  vim.defer_fn(poll, 20)
  local ok, err = coroutine.yield()
  if not ok then
    error(err or ("Timed out: " .. label), 0)
  end
end

local function current_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function assert_line(expected, label)
  local actual = current_lines()[1]
  assert(actual == expected,
    ("%s: expected first line %q, got %q"):format(label, expected, actual))
end

local function assert_cursor(expected_row, expected_column, label)
  local cursor = vim.api.nvim_win_get_cursor(0)
  assert(cursor[1] == expected_row and cursor[2] == expected_column,
    ("%s: expected cursor [%d, %d], got %s"):format(
      label, expected_row, expected_column, vim.inspect(cursor)))
end

local cursorhold_count = 0

local function wait_for_cursorhold(event_count, timeout_ms)
  wait_until(function()
    return cursorhold_count >= event_count
  end, timeout_ms, ("real CursorHold #%d (observed %d)"):format(event_count, cursorhold_count))
end

local function run()
  local ls = require("luasnip")
  local cmp = require("cmp")
  local lsp_config = require("lsp.config")

  -- This fixture is about snippet/editor events, not a language server session.
  vim.lsp.enable(lsp_config.servers, false)
  assert(#vim.lsp.get_clients() == 0, "unexpected LSP client attached to the snippet fixture")

  local trigger = "dotfilesIdleLifetime"
  local filetype = "lua"
  local fixture_key = "dotfiles-luasnip-idle-lifetime"

  vim.cmd("enew")
  vim.bo.filetype = filetype
  vim.wo.foldenable = false
  vim.wo.foldmethod = "manual"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "", "outside" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })

  ls.add_snippets(filetype, {
    ls.snippet(trigger, {
      ls.insert_node(1, "first"),
      ls.text_node(":"),
      ls.insert_node(2, "second"),
      ls.text_node("!"),
      ls.insert_node(0),
    }),
  }, { key = fixture_key })

  assert(ls.in_snippet() == false, "fresh buffer unexpectedly has an active snippet")
  assert(ls.jumpable(1) == false, "fresh buffer unexpectedly has a forward snippet jump")
  assert(ls.jumpable(-1) == false, "fresh buffer unexpectedly has a backward snippet jump")
  print("PASS: idle buffer starts without an active LuaSnip session")

  -- Enter Insert mode, type the trigger and dispatch the configured nvim-cmp
  -- Super-Tab mapping as separate real input batches. Keep diagnostics explicit:
  -- this test must distinguish a broken fixture from a plugin behavior failure.
  feed("i", function()
    assert(vim.fn.mode():sub(1, 1) == "i",
      "Neovim did not enter Insert mode before typing the snippet trigger (mode=" .. vim.fn.mode() .. ")")
  end)
  feed(trigger, function()
    assert(vim.fn.mode():sub(1, 1) == "i",
      "typing the snippet trigger left Insert mode (mode=" .. vim.fn.mode() .. ")")
  end)
  assert(ls.expandable(), "LuaSnip did not recognize the registered trigger at the cursor: " .. vim.inspect({
    line = vim.api.nvim_get_current_line(),
    cursor = vim.api.nvim_win_get_cursor(0),
    filetype = vim.bo.filetype,
    mode = vim.fn.mode(),
  }))
  print(("INFO: before Tab: mode=%s cmp.visible=%s mapping=%s"):format(
    vim.fn.mode(), tostring(cmp.visible()),
    vim.inspect(vim.fn.maparg("<Tab>", "i", false, true))))
  if cmp.visible() then
    feed("<C-e>")
    assert(vim.fn.mode():sub(1, 1) == "i",
      "aborting the visible completion menu left Insert mode (mode=" .. vim.fn.mode() .. ")")
  end
  feed("<Tab>")
  print(("INFO: after Tab: mode=%s line=%q in_snippet=%s forward=%s"):format(
    vim.fn.mode(), vim.api.nvim_get_current_line(), tostring(ls.in_snippet()), tostring(ls.jumpable(1))))

  assert(vim.fn.mode():sub(1, 1) == "i",
    "snippet expansion did not leave Neovim in Insert mode (mode=" .. vim.fn.mode() .. ")")
  assert_line("first:second!", "real Tab-triggered snippet expansion")
  assert_cursor(1, 0, "first insert node after expansion")
  assert(ls.in_snippet() == true, "expanded snippet is not active at its first insert node")
  assert(ls.jumpable(1) == true, "first insert node has no forward jump")
  assert(ls.jumpable(-1) == false, "first insert node unexpectedly has a backward jump")
  print("PASS: configured Insert-mode Tab expands the real LuaSnip fixture")

  -- Count real idle events after config/plugin autocmds have been registered.
  cursorhold_count = 0
  local group = vim.api.nvim_create_augroup("DotfilesLuaSnipIdleLifetimeTest", { clear = true })
  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    callback = function()
      cursorhold_count = cursorhold_count + 1
    end,
  })

  local configured_updatetime = vim.o.updatetime
  assert(configured_updatetime > 0, "&updatetime must be positive for the idle-event test")
  print(("INFO: testing real CursorHold after configured &updatetime=%dms"):format(configured_updatetime))

  feed("<Esc>")
  assert(vim.fn.mode():sub(1, 1) == "n", "Escape did not leave Insert mode")
  wait_for_cursorhold(1, configured_updatetime + 2500)

  assert(ls.in_snippet() == true, "first real CursorHold destroyed the active snippet region")
  assert(ls.jumpable(1) == true, "first real CursorHold destroyed the next insert-node jump")
  assert_line("first:second!", "snippet text after first CursorHold")
  print("PASS: first real CursorHold preserves the active snippet and its forward jump")

  -- A second idle cycle must not unlink the same session either.
  feed("i")
  feed("<Esc>")
  wait_for_cursorhold(2, configured_updatetime + 2500)

  assert(ls.in_snippet() == true, "repeated real CursorHold events destroyed the active snippet region")
  assert(ls.jumpable(1) == true, "repeated real CursorHold events destroyed the next insert-node jump")
  assert_line("first:second!", "snippet text after repeated CursorHold")
  print("PASS: repeated real CursorHold events preserve the active snippet session")

  -- Traverse the actual nvim-cmp mappings in both directions.
  feed("i")
  if cmp.visible() then feed("<C-e>") end
  feed("<Tab>")
  assert(ls.jumpable(-1) == true, "forward Tab did not reach the second insert node")
  assert(ls.jumpable(1) == true, "second insert node lost the exit-node jump")
  assert_line("first:second!", "forward jump to second insert node")
  assert_cursor(1, 6, "second insert node after forward Tab")

  if cmp.visible() then feed("<C-e>") end
  feed("<S-Tab>")
  assert(ls.jumpable(-1) == false, "Shift-Tab did not return to the first insert node")
  assert(ls.jumpable(1) == true, "backward jump lost the forward destination")
  assert_line("first:second!", "backward jump to first insert node")
  assert_cursor(1, 0, "first insert node after Shift-Tab")

  if cmp.visible() then feed("<C-e>") end
  feed("<Tab>")
  if cmp.visible() then feed("<C-e>") end
  feed("<Tab>")
  assert(ls.jumpable(1) == false, "the final insert node must not expose another forward jump")
  assert(ls.jumpable(-1) == true, "the final insert node should retain its backward jump")
  assert_line("first:second!", "navigation to the final insert node")
  assert_cursor(1, 13, "final insert node after forward Tab")
  print("PASS: configured Tab/Shift-Tab navigate forward, backward, and to the exhausted exit node")

  -- Move back into the snippet and then outside its region. LuaSnip's documented
  -- region_check_events should refocus to $0 on cursor movement, without an idle timer.
  if cmp.visible() then feed("<C-e>") end
  feed("<S-Tab>")
  assert(ls.jumpable(1) == true, "backward navigation from the exit node did not reach an insert node")
  assert(ls.jumpable(-1) == true, "second insert node lost its previous destination")
  assert_cursor(1, 6, "second insert node after backward Tab from exit")

  feed("<Esc>j")
  wait_until(function()
    return ls.in_snippet() == false and ls.jumpable(1) == false and ls.jumpable(-1) == true
  end, 2000,
  ("cursor movement did not leave/refocus the snippet to its exit node: in_snippet=%s forward=%s backward=%s cursor=%s"):format(
    tostring(ls.in_snippet()), tostring(ls.jumpable(1)), tostring(ls.jumpable(-1)),
    vim.inspect(vim.api.nvim_win_get_cursor(0))))
  print("PASS: leaving the snippet by cursor movement follows LuaSnip's region-exit behavior")

  -- A different buffer with no active snippet must remain harmless while idle.
  vim.cmd("enew")
  vim.bo.filetype = "text"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "outside" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert(ls.in_snippet() == false, "new buffer inherited an active snippet")
  assert(ls.jumpable(1) == false, "new buffer unexpectedly has a forward jump")
  assert(ls.jumpable(-1) == false, "new buffer unexpectedly has a backward jump")

  feed("i")
  feed("<Esc>")
  wait_for_cursorhold(3, configured_updatetime + 2500)
  assert(ls.in_snippet() == false, "idle CursorHold created an active snippet in an unrelated buffer")
  assert(ls.jumpable(1) == false, "idle CursorHold created a forward jump without a snippet")
  assert(ls.jumpable(-1) == false, "idle CursorHold created a backward jump without a snippet")
  vim.api.nvim_del_augroup_by_id(group)
  print("PASS: real CursorHold events are harmless when the current buffer has no active snippet")
end

local thread = coroutine.create(function()
  -- Do not wrap this in pcall/xpcall: LuaJIT 5.1 cannot yield through those
  -- C-call boundaries. resume_test handles errors when each yield resumes.
  run()
  print("PASS: LuaSnip idle lifetime and real editor navigation")
  vim.cmd("qa!")
end)

vim.defer_fn(function()
  local ok, err = coroutine.resume(thread)
  if not ok then
    io.stderr:write("[luasnip-idle-lifetime] " .. debug.traceback(thread, tostring(err)) .. "\\n")
    vim.cmd("cquit 1")
  end
end, 10)
