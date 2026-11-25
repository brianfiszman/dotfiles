-- Verify that ordinary Mason completion only fills parser gaps, while an
-- actual nvim-treesitter revision change keeps the explicit parser update path.
local function pass(message)
  print("PASS: " .. message)
end

local function expect_equal(expected, actual, label)
  assert(expected == actual,
    ("%s: expected %s, got %s"):format(label, vim.inspect(expected), vim.inspect(actual)))
  pass(label)
end

local expected_parsers = {
  "c", "lua", "luadoc", "go", "javascript", "typescript", "json", "json5", "jsdoc", "yaml",
  "xml", "vim", "vimdoc", "tsx", "scheme", "make", "dot", "dockerfile", "csv", "diff",
  "gitignore", "gitcommit", "git_config", "git_rebase", "gitattributes", "css", "comment",
  "gomod", "gosum", "gowork", "html", "ini", "markdown", "markdown_inline", "passwd",
  "proto", "scss", "sql", "regex", "bash", "helm",
}

local treesitter = require("nvim-treesitter")
local installed = {}
for _, language in ipairs(treesitter.get_installed("parsers")) do
  installed[language] = true
end
for _, language in ipairs(expected_parsers) do
  assert(installed[language], "fixture is missing configured parser: " .. language)
end
pass(("fixture contains all %d configured compiled parsers"):format(#expected_parsers))

local original_update = treesitter.update
local update_calls = 0
treesitter.update = function(...)
  update_calls = update_calls + 1
  error("normal parser provisioning must not call nvim-treesitter.update")
end

-- Drive the real User event used by mason-tool-installer. Every parser is
-- already present, so provisioning must report readiness without refreshing
-- any compiled parser.
vim.api.nvim_exec_autocmds("User", {
  pattern = "MasonToolsUpdateCompleted",
  modeline = false,
})
expect_equal(0, update_calls, "Mason completion does not update existing parsers")
expect_equal(true, vim.g.dotfiles_treesitter_ready, "Mason completion keeps Treesitter ready")
expect_equal(nil, vim.g.dotfiles_treesitter_error, "Mason completion leaves no setup error")

local plugin = assert(
  require("lazy.core.config").plugins["nvim-treesitter"],
  "nvim-treesitter plugin is missing from lazy.nvim"
)
assert(type(plugin.build) == "function", "nvim-treesitter explicit build hook is missing")
local original_revision = plugin._.updated
local original_cloned = plugin._.cloned
local original_executable = vim.fn.executable

local function install_update_spy()
  treesitter.update = function(languages, opts)
    update_calls = update_calls + 1
    assert(vim.deep_equal(expected_parsers, languages),
      "plugin update must refresh exactly the configured parser set")
    assert(opts and opts.summary == true, "plugin update must retain summary output")
    return {
      wait = function(timeout)
        assert(timeout == 20 * 60 * 1000, "plugin update must use the parser install timeout")
        return true
      end,
    }
  end
end

install_update_spy()

-- lazy.nvim force-runs configured build hooks when a cached checkout is
-- restored. An unchanged locked revision must preserve the parser cache.
plugin._.cloned = false
plugin._.updated = { from = "same-locked-commit", to = "same-locked-commit" }
plugin.build(plugin)
expect_equal(0, update_calls, "unchanged nvim-treesitter build preserves parsers")

-- A real plugin update may happen before Mason has installed tree-sitter-cli
-- on a cold machine. Preserve the pending update request and consume it after
-- Mason emits its genuine completion event; do not accidentally update parsers
-- during ordinary first-time provisioning.
vim.fn.executable = function(name)
  if name == "tree-sitter" then
    return 0
  end
  return original_executable(name)
end
plugin._.updated = { from = string.rep("a", 40), to = string.rep("b", 40) }
plugin.build(plugin)
expect_equal(0, update_calls, "changed plugin defers parser update while Mason CLI is missing")

vim.fn.executable = function(name)
  if name == "tree-sitter" then
    return 1
  end
  return original_executable(name)
end
vim.api.nvim_exec_autocmds("User", {
  pattern = "MasonToolsUpdateCompleted",
  modeline = false,
})
expect_equal(1, update_calls, "Mason completion performs the deferred plugin parser update")
expect_equal(true, vim.g.dotfiles_treesitter_ready, "deferred parser update keeps Treesitter ready")

vim.fn.executable = original_executable
treesitter.update = original_update
plugin._.updated = original_revision
plugin._.cloned = original_cloned

print("PASS: Treesitter provisioning and explicit update policy")
