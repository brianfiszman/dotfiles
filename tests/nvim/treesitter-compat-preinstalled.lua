-- Verify that the startup init hook patches a legacy Treesitter checkout
-- that already existed before this configuration revision was installed.
local expected_commit = "85168f15808d89b0222313652b9d2777eda3cb08"
local plugin_dir = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
local patch = vim.fn.stdpath("config") .. "/patches/nvim-treesitter-neovim-0.12.patch"
local query_file = plugin_dir .. "/lua/nvim-treesitter/query_predicates.lua"

assert(vim.fn.has("nvim-0.12") == 1, "this regression test is only for Neovim 0.12+")

local revision = vim.system({
  "git", "-C", plugin_dir, "rev-parse", "HEAD",
}, { text = true }):wait()
assert(revision.code == 0,
  "could not inspect the installed nvim-treesitter checkout: " .. (revision.stderr or "unknown error"))

local actual_commit = (revision.stdout or ""):gsub("%s+$", "")
assert(actual_commit == expected_commit,
  ("nvim-treesitter revision expected %s, got %s"):format(expected_commit, actual_commit))

local query_source = table.concat(vim.fn.readfile(query_file), "\n")
assert(query_source:find("local function get_node%(match, id%)"),
  "Neovim 0.12 compatibility helper was not applied during startup")

local reverse_check = vim.system({
  "git", "-C", plugin_dir, "apply", "--reverse", "--check", patch,
}, { text = true }):wait()
assert(reverse_check.code == 0,
  "compatibility patch is not cleanly applied: " .. (reverse_check.stderr or reverse_check.stdout or "unknown patch state"))

print("PASS: normal startup patches a pre-existing legacy nvim-treesitter checkout before plugin loading")
