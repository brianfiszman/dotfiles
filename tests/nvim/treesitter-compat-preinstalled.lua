-- Verify migration from the previous on-disk patch to the in-memory adapter.
local expected_commit = "85168f15808d89b0222313652b9d2777eda3cb08"
local treesitter_spec = require("lazy.core.config").plugins["nvim-treesitter"]
assert(treesitter_spec and treesitter_spec.pin == true,
  "legacy nvim-treesitter must be pinned until its API migration is validated")
local plugin_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
local patch = vim.fn.stdpath("config") .. "/patches/nvim-treesitter-neovim-0.12.patch"
local query_file = "lua/nvim-treesitter/query_predicates.lua"
local module_name = "nvim-treesitter.query_predicates"

assert(vim.fn.has("nvim-0.12") == 1, "this regression test is only for Neovim 0.12+")

local function git(args)
  local command = { "git", "-C", plugin_dir }
  vim.list_extend(command, args)
  return vim.system(command, { text = true }):wait()
end

local revision = git({ "rev-parse", "HEAD" })
assert(revision.code == 0,
  "could not inspect the installed nvim-treesitter checkout: " .. (revision.stderr or "unknown error"))
local actual_commit = (revision.stdout or ""):gsub("%s+$", "")
assert(actual_commit == expected_commit,
  ("nvim-treesitter revision expected %s, got %s"):format(expected_commit, actual_commit))

local forward_check = git({ "apply", "--check", patch })
assert(forward_check.code == 0,
  "the previous disk patch was not removed from the installed checkout: "
    .. (forward_check.stderr or forward_check.stdout or "unknown patch state"))

local clean_file = git({ "diff", "--quiet", "--", query_file })
assert(clean_file.code == 0,
  "query_predicates.lua is still modified in the plugin checkout: "
    .. (clean_file.stderr or clean_file.stdout or "git diff reported changes"))

assert(type(package.preload[module_name]) == "function" or package.loaded[module_name] ~= nil,
  "the in-memory query-predicate adapter was not installed before plugin loading")

-- Exercise an actual legacy custom predicate. On Neovim 0.12 the capture is a
-- list; the adapter must pass one TSNode to the locked legacy handler.
local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "const answer = 42;" })
vim.bo[bufnr].filetype = "javascript"
local parser = vim.treesitter.get_parser(bufnr, "javascript")
local tree = parser:parse()[1]
local query = vim.treesitter.query.parse("javascript", [[
  ((identifier) @captured
    (#kind-eq? @captured "identifier"))
]])
local iter = query:iter_matches(tree:root(), bufnr)
local pattern, captures = iter()
assert(pattern ~= nil and captures ~= nil,
  "legacy #kind-eq? predicate did not match a JavaScript identifier through the adapter")
vim.api.nvim_buf_delete(bufnr, { force = true })

print("PASS: previous on-disk Treesitter patch is migrated without leaving a Git modification")
print("PASS: Neovim 0.12 legacy query predicates adapt capture lists in memory")
