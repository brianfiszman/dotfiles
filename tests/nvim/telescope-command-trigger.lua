-- Prove :Telescope itself is a working first-use trigger in a fresh process.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
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

local function picker_has_file(name)
  local picker = current_picker()
  if not picker or not picker.manager then
    return false
  end
  for entry in picker.manager:iter() do
    if tostring(entry.filename or entry.value or ""):find(name, 1, true) then
      return true
    end
  end
  return false
end

if vim.v.vim_did_enter == 0 then
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end
local leader = vim.g.mapleader or "\\\\"
wait_for("VeryLazy project and LazyGit integrations to initialize", 30000, function()
  return package.loaded["project_nvim"] ~= nil
    and vim.fn.maparg(leader .. "gg", "n") ~= ""
end)
assert(vim.fn.exists(":LazyGit") == 2, "LazyGit command is missing after VeryLazy")

assert(package.loaded["telescope"] == nil, "Telescope loaded before the direct command test")
assert(vim.fn.exists(":Telescope") == 2, ":Telescope command trigger is missing")
pass("fresh startup leaves Telescope unloaded while registering :Telescope")

local workspace = vim.fn.tempname() .. "-telescope-command"
assert(vim.fn.mkdir(workspace, "p") == 1 or vim.fn.isdirectory(workspace) == 1,
  "could not create command-trigger fixture directory")
local filename = "command-trigger-telescope-fixture.txt"
assert(vim.fn.writefile({ "direct command first-use result" }, workspace .. "/" .. filename) == 0,
  "could not create command-trigger fixture")
vim.cmd("cd " .. vim.fn.fnameescape(workspace))

print("STEP: invoking :Telescope find_files directly")
vim.cmd("Telescope find_files")
wait_for("direct command to open Find Files picker", 30000, function()
  local picker = current_picker()
  return picker ~= nil and picker.prompt_title == "Find Files"
end)
wait_for("direct command picker to return its fixture", 30000, function()
  return picker_has_file(filename)
end)

assert(package.loaded["telescope"] ~= nil, "direct :Telescope command did not load Telescope")
assert(vim.fn.exists(":Telescope") == 2, "Telescope command disappeared after loading")
assert(type(require("telescope").extensions.media_files.media_files) == "function",
  "media-files extension was not initialized by direct command trigger")
pass(":Telescope loads Telescope on demand and returns the expected file")
local picker = current_picker()
require("telescope.actions").close(picker.prompt_bufnr)
wait_for("direct command picker cleanup", 10000, function()
  return current_picker() == nil
end)
vim.fn.delete(workspace, "rf")
