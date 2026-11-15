-- Exercise the actual LazyUpdatePre/LazyUpdate events against Git checkout collisions.
local config = require("lazy.core.config")
local treesitter = config.plugins["nvim-treesitter"]
assert(treesitter and treesitter.pin == true,
  "legacy nvim-treesitter must remain pinned until its API migration is validated")

local root = vim.fn.tempname() .. "-lazy-update-preflight"
local repo = root .. "/plugin"
local tags_file = repo .. "/doc/tags"
local keep_file = repo .. "/keep-untracked.txt"
vim.fn.mkdir(repo, "p")

local function git(args, allow_failure)
  local command = { "git", "-C", repo }
  vim.list_extend(command, args)
  local result = vim.system(command, { text = true }):wait()
  if not allow_failure and result.code ~= 0 then
    error(("git %s failed (%d): %s"):format(
      table.concat(args, " "), result.code, result.stderr or result.stdout or ""
    ))
  end
  return result
end

local function write(path, lines)
  local parent = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(parent, "p")
  assert(vim.fn.writefile(lines, path) == 0, "could not write fixture file " .. path)
end

local function read_first_line(path)
  local lines = vim.fn.readfile(path)
  return lines[1]
end

git({ "init" })
git({ "config", "user.name", "Dotfiles Integration Test" })
git({ "config", "user.email", "dotfiles-test@example.invalid" })
write(repo .. "/README.md", { "base commit" })
git({ "add", "README.md" })
git({ "commit", "-m", "base without generated help tags" })
local base = (git({ "rev-parse", "HEAD" }).stdout or ""):gsub("%s+$", "")

git({ "checkout", "-b", "upstream-adds-tags" })
write(tags_file, { "tracked upstream help tag" })
git({ "add", "doc/tags" })
git({ "commit", "-m", "upstream starts tracking doc/tags" })
git({ "checkout", base })

-- Model the generated file left by lazy.nvim's previous :helptags task.
write(tags_file, { "generated local help tag" })
write(keep_file, { "unrelated user file must survive" })

local blocked = git({ "checkout", "upstream-adds-tags" }, true)
assert(blocked.code ~= 0,
  "fixture did not reproduce Git refusing to overwrite untracked doc/tags")
assert((blocked.stderr or ""):find("would be overwritten", 1, true),
  "checkout failed for an unexpected reason: " .. (blocked.stderr or ""))

local fixture_key = "__dotfiles_lazy_update_preflight_fixture"
local previous = config.plugins[fixture_key]
config.plugins[fixture_key] = {
  name = fixture_key,
  dir = repo,
  url = "https://example.invalid/dotfiles-test",
  _ = { installed = true, is_local = false },
}

vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdatePre", modeline = false })

assert((vim.uv or vim.loop).fs_stat(tags_file) == nil,
  "LazyUpdatePre did not remove the generated untracked doc/tags")
assert(read_first_line(keep_file) == "unrelated user file must survive",
  "LazyUpdatePre removed an unrelated untracked file")

local checkout = git({ "checkout", "upstream-adds-tags" }, true)
assert(checkout.code == 0,
  "Git checkout still failed after LazyUpdatePre cleanup: " .. (checkout.stderr or checkout.stdout or ""))
assert(read_first_line(tags_file) == "tracked upstream help tag",
  "the upstream tracked doc/tags was not restored correctly")

vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdate", modeline = false })
assert(read_first_line(tags_file) == "tracked upstream help tag",
  "the post-update handler changed upstream-tracked doc/tags")

-- Model a different installed plugin that was not updated. Its old, untracked
-- tags file must be regenerated when LazyUpdate fires.
git({ "checkout", base })
write(repo .. "/doc/help.txt", { "*lazy-update-test-tag* A generated help-tag fixture" })
write(tags_file, { "old generated index" })
vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdatePre", modeline = false })
assert((vim.uv or vim.loop).fs_stat(tags_file) == nil,
  "second LazyUpdatePre did not remove the generated untracked doc/tags")
assert(read_first_line(keep_file) == "unrelated user file must survive",
  "second LazyUpdatePre removed an unrelated untracked file")
vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdate", modeline = false })
assert((vim.uv or vim.loop).fs_stat(tags_file) ~= nil,
  "LazyUpdate did not regenerate tags for a plugin that was not updated")
local generated_tags = table.concat(vim.fn.readfile(tags_file), "\n")
assert(generated_tags:find("lazy%-update%-test%-tag"),
  "regenerated tags file does not contain the fixture help tag")

config.plugins[fixture_key] = previous
vim.fn.delete(root, "rf")

print("PASS: LazyUpdatePre removes only untracked generated doc/tags files")
print("PASS: tracked upstream tags and unrelated untracked files are preserved")
print("PASS: the previously blocked Git checkout succeeds after preflight")
print("PASS: help tags are regenerated when an installed plugin was not updated")
