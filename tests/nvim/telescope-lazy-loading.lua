-- Verify Telescope and its extensions stay out of ordinary startup,
-- then exercise real user mappings against real file and grep results.

local function pass(message)
  print(("PASS: %s"):format(message))
end

local function wait_for(description, timeout_ms, predicate)
  print(("WAIT: %s"):format(description))
  assert(vim.wait(timeout_ms, predicate, 25), ("Timed out waiting for %s"):format(description))
end

local function enter_headless_ui()
  enter_headless_ui()
local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feed(keys)
  vim.api.nvim_feedkeys(termcodes(keys), "xt", false)
end

local function current_picker()
  if not package.loaded["telescope.state"] then
    return nil
  end
  local state = require("telescope.state")
  for _, bufnr in ipairs(state.get_existing_prompt_bufnrs()) do
    local status = state.get_status(bufnr)
    if status and status.picker and not status.picker.closed then
      return status.picker, bufnr
    end
  end
  return nil
end

local function wait_for_picker(title)
  wait_for(("Telescope picker %q"):format(title), 30000, function()
    local picker = current_picker()
    return picker ~= nil and picker.prompt_title == title
  end)
  local picker, prompt_bufnr = current_picker()
  assert(picker and picker.prompt_bufnr == prompt_bufnr, "Telescope prompt state is inconsistent")
  return picker, prompt_bufnr
end

local function picker_has_entry(predicate)
  local picker = current_picker()
  if not picker or not picker.manager then
    return false
  end
  for entry in picker.manager:iter() do
    if predicate(entry) then
      return true
    end
  end
  return false
end

local function close_picker()
  local picker = current_picker()
  assert(picker ~= nil, "Expected an open Telescope picker before closing it")
  -- This is test cleanup, not the mapping under test. Use Telescope's close
  -- action directly so cleanup does not depend on the prompt's current mode.
  require("telescope.actions").close(picker.prompt_bufnr)
  wait_for("Telescope picker to close", 10000, function()
    return current_picker() == nil
  end)
end

if vim.v.vim_did_enter == 0 then
  print("STEP: dispatching VimEnter so VeryLazy integrations are initialized")
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end

local leader = vim.g.mapleader or "\\"
wait_for("VeryLazy project and LazyGit mappings", 30000, function()
  return vim.fn.maparg(leader .. "gg", "n") ~= ""
    and package.loaded["project_nvim"] ~= nil
end)

assert(package.loaded["scope"] ~= nil, "Scope tab-buffer behavior did not initialize")
assert(vim.fn.exists(":ScopeMoveBuf") == 2, "ScopeMoveBuf is missing")
assert(vim.fn.exists(":LazyGit") == 2, "LazyGit command was not registered")
pass("Scope and LazyGit integrations initialize without loading Telescope")

local telescope_modules = {
  "telescope",
  "telescope.builtin",
  "telescope.actions",
  "telescope._extensions.fzf",
  "telescope._extensions.media_files",
  "telescope._extensions.projects",
  "telescope._extensions.scope",
  "telescope._extensions.lazygit",
}
for _, module in ipairs(telescope_modules) do
  assert(package.loaded[module] == nil, module .. " loaded during idle startup/VeryLazy")
end
assert(vim.fn.exists(":Telescope") == 2, ":Telescope lazy command trigger is not registered")
pass("Telescope and all extensions remain unloaded after normal startup and VeryLazy")

local mappings = { "bb", "fb", "fc", "ff", "fp", "ft", "fh", "fl", "fr" }
for _, suffix in ipairs(mappings) do
  local lhs = leader .. suffix
  wait_for(("lazy trigger %s"):format(lhs), 10000, function()
    return vim.fn.maparg(lhs, "n") ~= ""
  end)
end
pass("all nine existing Telescope mappings are registered as first-use triggers")

local workspace = vim.fn.tempname() .. "-telescope"
local source_dir = workspace .. "/src"
assert(vim.fn.mkdir(source_dir, "p") == 1 or vim.fn.isdirectory(source_dir) == 1,
  "could not create Telescope fixture directory")
assert(vim.fn.mkdir(workspace .. "/.git", "p") == 1 or vim.fn.isdirectory(workspace .. "/.git") == 1,
  "could not create project root marker")
local fixture = source_dir .. "/needle-telescope-result.txt"
local marker = "unique_telescope_live_grep_marker"
assert(vim.fn.writefile({ marker, "second fixture line" }, fixture) == 0, "could not write Telescope fixture")
vim.cmd("cd " .. vim.fn.fnameescape(workspace))
vim.cmd("edit " .. vim.fn.fnameescape(fixture))
vim.cmd("enew")

print("STEP: invoking <leader>fp as the first Telescope action")
feed(leader .. "fp")
wait_for_picker("Recent Projects")
pass("<leader>fp is a working first-use trigger for the project.nvim extension")
close_picker()

local telescope = require("telescope")
local config = require("telescope.config").values
assert(config.pickers.find_files.theme == "dropdown", "Telescope picker configuration was not applied")
assert(config.extensions.media_files.find_cmd == "rg", "media-files extension options were not applied")
assert(config.extensions.fzf.fuzzy == true, "fzf extension options were not applied")
for _, extension in ipairs({ "projects", "scope", "lazygit", "media_files" }) do
  assert(telescope.extensions[extension] ~= nil, ("Telescope extension %s was not registered"):format(extension))
end
assert(type(telescope.extensions.projects.projects) == "function", "project picker export is missing")
assert(type(telescope.extensions.scope.buffers) == "function", "Scope buffers picker export is missing")
assert(type(telescope.extensions.lazygit.lazygit) == "function", "LazyGit picker export is missing")
assert(type(telescope.extensions.media_files.media_files) == "function", "media-files picker export is missing")
assert(package.loaded["telescope._extensions.fzf"] ~= nil, "fzf-native extension did not load")
pass("Telescope setup registered project, Scope, LazyGit, media-files, and compiled fzf extensions")

for _, suffix in ipairs(mappings) do
  assert(vim.fn.maparg(leader .. suffix, "n") ~= "", ("mapping %s disappeared after Telescope setup"):format(leader .. suffix))
end
pass("all nine documented picker mappings remain available after Telescope loads")

print("STEP: invoking the real <leader>ff mapping")
feed(leader .. "ff")
wait_for_picker("Find Files")
wait_for("find_files to return the fixture", 30000, function()
  return picker_has_entry(function(entry)
    return tostring(entry.filename or entry.value or ""):find("needle-telescope-result.txt", 1, true) ~= nil
  end)
end)
pass("the real <leader>ff mapping opens find_files and returns the expected file")
close_picker()

print("STEP: invoking the real <leader>ft mapping and typing a search query")
feed(leader .. "ft")
local grep_picker = wait_for_picker("Live Grep")
vim.api.nvim_set_current_win(grep_picker.prompt_win)
feed(marker)
wait_for("live_grep to return the fixture marker", 30000, function()
  return picker_has_entry(function(entry)
    return tostring(entry.text or ""):find(marker, 1, true) ~= nil
      and tostring(entry.filename or ""):find("needle-telescope-result.txt", 1, true) ~= nil
  end)
end)
pass("the real <leader>ft mapping runs ripgrep and returns the expected file/content")
close_picker()

print("STEP: invoking the existing <C-p> project navigation mapping")
feed("<C-p>")
wait_for_picker("Recent Projects")
pass("<C-p> still opens the project.nvim Telescope extension")
close_picker()

if vim.fn.executable("chafa") == 1 then
  print("STEP: exercising the media-files picker with Chafa available")
  feed(":Telescope media_files<CR>")
  wait_for_picker("Media Files")
  pass("media-files picker opens when its required Chafa preview tool is installed")
  close_picker()
else
  print("SKIP: media-files preview interaction requires Chafa; extension loading/configuration is verified")
end

vim.fn.delete(workspace, "rf")
pass("Telescope first-use integration checks completed")
