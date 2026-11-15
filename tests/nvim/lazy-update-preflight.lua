-- Exercise the actual LazyUpdatePre/LazyUpdate and LazyRestorePre/LazyRestore
-- events against Git checkout collisions, including Lazy's subsequent docs task.
local config = require("lazy.core.config")
local treesitter = config.plugins["nvim-treesitter"]
assert(treesitter and treesitter.branch == "main",
  "nvim-treesitter must track the current upstream main API")
local lockfile_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
local lockfile = vim.json.decode(table.concat(vim.fn.readfile(lockfile_path), "\\n"))
assert(lockfile["nvim-treesitter"] and lockfile["nvim-treesitter"].branch == "main",
  "lazy-lock.json must record the current nvim-treesitter main branch")

local root = vim.fn.tempname() .. "-lazy-update-preflight"
local repo = root .. "/plugin"
local doc_dir = repo .. "/doc"
local tags_file = doc_dir .. "/tags"
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

local function read(path)
  return table.concat(vim.fn.readfile(path), "\n")
end

local function generate_help_tags(path)
  local ok, result = pcall(vim.api.nvim_cmd, {
    cmd = "helptags",
    args = { path },
  }, { output = true })
  assert(ok, "helptags failed for " .. path .. ": " .. tostring(result))
end

git({ "init" })
git({ "config", "user.name", "Dotfiles Integration Test" })
git({ "config", "user.email", "dotfiles-test@example.invalid" })
write(repo .. "/README.md", { "base commit" })
git({ "add", "README.md" })
git({ "commit", "-m", "base commit without generated help tags" })
local base = (git({ "rev-parse", "HEAD" }).stdout or ""):gsub("%s+$", "")

-- Model the upstream revision that newly tracks a genuine :helptags index.
write(doc_dir .. "/help.txt", {
  "*upstream-help-tag* Help text tracked by the upstream revision",
})
generate_help_tags(doc_dir)
local upstream_tags = read(tags_file)
assert(upstream_tags:find("upstream%-help%-tag"),
  "the upstream fixture did not generate its expected help tag")
git({ "add", "doc/help.txt", "doc/tags" })
git({ "commit", "-m", "upstream starts tracking generated doc/tags" })
git({ "branch", "upstream-adds-tags" })
git({ "checkout", base })

-- Model the generated untracked index left by Lazy's prior docs task.
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
assert(read(keep_file) == "unrelated user file must survive",
  "LazyUpdatePre removed an unrelated untracked file")

local checkout = git({ "checkout", "upstream-adds-tags" }, true)
assert(checkout.code == 0,
  "Git checkout still failed after LazyUpdatePre cleanup: " .. (checkout.stderr or checkout.stdout or ""))
assert(read(tags_file):find("upstream%-help%-tag"),
  "Git checkout did not restore the upstream-tracked help tags")

-- lazy.nvim runs its real plugin.docs task after checkout. Re-run the exact
-- :helptags operation here and prove that it leaves the newly tracked index
-- intact rather than dirtying the plugin checkout.
generate_help_tags(doc_dir)
assert(git({ "diff", "--quiet", "--", "doc/tags" }).code == 0,
  "Lazy's post-checkout :helptags task modified the upstream-tracked doc/tags")
assert(read(tags_file):find("upstream%-help%-tag"),
  "Lazy's post-checkout :helptags task lost the upstream help tag")

vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdate", modeline = false })
assert(read(tags_file):find("upstream%-help%-tag"),
  "the LazyUpdate post-hook changed upstream-tracked doc/tags")

-- A later preflight must also leave an already tracked tags file untouched.
local tracked_contents = read(tags_file)
vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdatePre", modeline = false })
assert((vim.uv or vim.loop).fs_stat(tags_file) ~= nil,
  "LazyUpdatePre removed a tracked upstream doc/tags file")
assert(read(tags_file) == tracked_contents,
  "LazyUpdatePre modified a tracked upstream doc/tags file")
vim.api.nvim_exec_autocmds("User", { pattern = "LazyUpdate", modeline = false })

-- Model a different installed plugin that is not updated during restore. Its
-- generated tags file must be recreated after LazyRestorePre removes it.
git({ "checkout", base })
write(doc_dir .. "/local-help.txt", {
  "*lazy-restore-test-tag* A generated help-tag fixture",
})
write(tags_file, { "old generated index" })
vim.api.nvim_exec_autocmds("User", { pattern = "LazyRestorePre", modeline = false })
assert((vim.uv or vim.loop).fs_stat(tags_file) == nil,
  "LazyRestorePre did not remove the generated untracked doc/tags")
assert(read(keep_file) == "unrelated user file must survive",
  "LazyRestorePre removed an unrelated untracked file")
vim.api.nvim_exec_autocmds("User", { pattern = "LazyRestore", modeline = false })
assert((vim.uv or vim.loop).fs_stat(tags_file) ~= nil,
  "LazyRestore did not regenerate tags for a plugin that was not updated")
local generated_tags = read(tags_file)
assert(generated_tags:find("lazy%-restore%-test%-tag"),
  "regenerated tags file does not contain the fixture help tag")

config.plugins[fixture_key] = previous
vim.fn.delete(root, "rf")

print("PASS: LazyUpdatePre removes only untracked generated doc/tags files")
print("PASS: tracked upstream tags and unrelated untracked files are preserved")
print("PASS: Git checkout succeeds after the actual preflight")
print("PASS: Lazy's post-checkout :helptags task leaves upstream tags clean")
print("PASS: help tags are regenerated when an installed plugin is not updated")
