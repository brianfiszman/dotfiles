-- Prove project.nvim's existing <C-p> mapping can load Telescope through
-- Lazy's module autoload path when no Telescope command/key was used first.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
end

local function enter_headless_ui()
  -- core.general.lua targets the maintainer's macOS shell. This isolated Linux
  -- process uses Bash so unrelated BufEnter integrations can start their jobs.
  local bash = vim.fn.exepath("bash")
  assert(bash ~= "", "headless integration test requires bash")
  vim.o.shell = bash
  vim.env.SHELL = bash

  if vim.v.vim_did_enter == 0 then
    print("STEP: dispatching VimEnter in the headless process")
    vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
  end

  -- lazy.nvim waits for UIEnter before emitting VeryLazy when VimEnter ran
  -- without a UI. Wait until its LazyDone callback has installed that barrier.
  wait_for("lazy.nvim LazyDone startup barrier", 30000, function()
    return #vim.api.nvim_get_autocmds({ event = "User", pattern = "LazyDone" }) == 0
  end)

  if vim.g.did_very_lazy ~= true then
    print("STEP: dispatching UIEnter so lazy.nvim can emit VeryLazy")
    vim.api.nvim_exec_autocmds("UIEnter", { modeline = false })
  end
  wait_for("lazy.nvim VeryLazy event", 30000, function()
    return vim.g.did_very_lazy == true
  end)
end

local function current_picker()
  if not package.loaded["telescope.state"] then
    return nil
  end
  local state = require("telescope.state")
  for _, bufnr in ipairs(state.get_existing_prompt_bufnrs()) do
    local status = state.get_status(bufnr)
    if status and status.picker and not status.picker.closed then
      return status.picker
    end
  end
  return nil
end

enter_headless_ui()
wait_for("VeryLazy project.nvim setup to register <C-p>", 30000, function()
  return package.loaded["project_nvim"] ~= nil and vim.fn.maparg("<C-p>", "n") ~= ""
end)

assert(package.loaded["telescope"] == nil, "Telescope loaded before project module trigger")
pass("project.nvim is ready while Telescope remains unloaded")

local mapping = vim.fn.maparg("<C-p>", "n", false, true)
assert(type(mapping) == "table", "<C-p> has no mapping metadata")
assert(type(mapping.rhs) == "string" and mapping.rhs:find("require('telescope')", 1, true),
  "<C-p> no longer enters Telescope through the module API")
print(("MAPPING: <C-p> rhs=%s"):format(mapping.rhs))

print("STEP: invoking the real project.nvim <C-p> mapping")
local keys = vim.api.nvim_replace_termcodes("<C-p>", true, false, true)
vim.api.nvim_feedkeys(keys, "xt", false)

wait_for("project.nvim Telescope picker", 30000, function()
  local picker = current_picker()
  return picker ~= nil and picker.prompt_title == "Recent Projects"
end)

assert(package.loaded["telescope"] ~= nil, "<C-p> did not lazy-load Telescope")
assert(type(require("telescope").extensions.projects.projects) == "function",
  "project.nvim extension did not load through <C-p>")
pass("<C-p> lazy-loads Telescope through require() and opens Recent Projects")

local picker = current_picker()
require("telescope.actions").close(picker.prompt_bufnr)
wait_for("project picker cleanup", 10000, function()
  return current_picker() == nil
end)
