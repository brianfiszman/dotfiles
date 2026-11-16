-- Prove project.nvim's existing <C-p> mapping can load Telescope through
-- Lazy's module autoload path when no Telescope command/key was used first.

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

if vim.v.vim_did_enter == 0 then
  print("STEP: dispatching VimEnter so project.nvim initializes")
  vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
end

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
