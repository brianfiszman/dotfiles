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

-- With an actually empty parser install directory, ordinary provisioning
-- must call install() for every configured parser and still never update.
-- Use nvim-treesitter's real get_installed() filesystem path; only the
-- network/compile-backed install future is replaced by a deterministic spy.
local config = require("nvim-treesitter.config")
local original_install = treesitter.install
local original_executable_for_provision = vim.fn.executable
local original_install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site")
local isolated_install_dir = vim.fn.tempname()
config.setup({ install_dir = isolated_install_dir })
expect_equal({}, treesitter.get_installed("parsers"),
  "isolated parser fixture starts with no installed parsers")

local install_calls = 0
treesitter.install = function(languages, opts)
  install_calls = install_calls + 1
  assert(vim.deep_equal(expected_parsers, languages),
    "provisioning must install exactly the missing configured parsers")
  assert(opts and opts.summary == true, "missing-parser install must keep summary output")
  return {
    wait = function(timeout)
      assert(timeout == 20 * 60 * 1000, "missing-parser install must use the parser install timeout")
      return true
    end,
  }
end
expect_equal(treesitter.install, require("nvim-treesitter").install,
  "provisioning test controls the same nvim-treesitter install API")

-- Invoke the real callback registered by the configuration. The temporary
-- install root guarantees that the real get_installed() implementation sees
-- parser gaps without mocking its result or touching the workspace cache.
local provision_autocmds = vim.api.nvim_get_autocmds({
  event = "User",
  pattern = "MasonToolsUpdateCompleted",
  group = "DotfilesTreesitter",
})
expect_equal(1, #provision_autocmds, "one Treesitter provisioning callback is registered")
local provision_callback = assert(provision_autocmds[1].callback,
  "Treesitter provisioning autocmd must be a Lua callback")
assert(vim.fn.exepath("tree-sitter") ~= "",
  "the real pinned tree-sitter CLI must be available for provisioning")
local callback_ok, callback_error = pcall(provision_callback)
assert(callback_ok, callback_error)
expect_equal(#expected_parsers, install_calls > 0 and #expected_parsers or 0,
  "missing-parser provisioning reaches the install API")
expect_equal(1, install_calls, "Mason completion installs missing configured parsers")
expect_equal(0, update_calls, "installing missing parsers does not update existing parsers")

treesitter.install = original_install
config.setup({ install_dir = original_install_dir })

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

-- During CI plugin restore, even an already-cached Mason CLI must not
-- start parser work in the restore process. Defer the revision update to the
-- following normal-startup process.
local original_skip = vim.env.DOTFILES_SKIP_TREESITTER_PROVISIONING
vim.env.DOTFILES_SKIP_TREESITTER_PROVISIONING = "1"
plugin._.updated = { from = string.rep("a", 40), to = string.rep("b", 40) }
plugin.build(plugin)
expect_equal(0, update_calls, "CI plugin restore defers parser work despite a cached CLI")
vim.env.DOTFILES_SKIP_TREESITTER_PROVISIONING = original_skip
vim.api.nvim_exec_autocmds("User", {
  pattern = "MasonToolsUpdateCompleted",
  modeline = false,
})
expect_equal(1, update_calls, "normal startup consumes the deferred plugin parser update")

-- A real plugin update may also happen before Mason has installed the CLI on a
-- cold machine. Preserve the update request until the genuine completion event.
vim.fn.executable = function(name)
  if name == "tree-sitter" then
    return 0
  end
  return original_executable(name)
end
plugin._.updated = { from = string.rep("c", 40), to = string.rep("d", 40) }
plugin.build(plugin)
expect_equal(1, update_calls, "changed plugin defers parser update while Mason CLI is missing")

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
expect_equal(2, update_calls, "Mason completion performs the update deferred by a missing CLI")
expect_equal(true, vim.g.dotfiles_treesitter_ready, "deferred parser update keeps Treesitter ready")

vim.fn.executable = original_executable
vim.env.DOTFILES_SKIP_TREESITTER_PROVISIONING = original_skip
treesitter.update = original_update
plugin._.updated = original_revision
plugin._.cloned = original_cloned

print("PASS: Treesitter provisioning and explicit update policy")
