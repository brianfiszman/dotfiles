local function run_test()
  local config_dir = vim.env.DOTFILES_NVIM_CONFIG
  assert(config_dir and config_dir ~= "", "DOTFILES_NVIM_CONFIG must point to the installed Neovim config")
  vim.opt.rtp:prepend(config_dir)

  local provider = require("core.python-provider")
  provider.configure_host()
  provider.setup()

  local test_script = vim.env.DOTFILES_NVIM_TEST_SCRIPT
  assert(test_script and test_script ~= "", "DOTFILES_NVIM_TEST_SCRIPT must point to a provider test")
  dofile(test_script)
end

-- A top-level test error must terminate headless Neovim. Without this guard,
-- an assertion can abort the script before qa! and leave the editor process
-- alive until GitHub Actions kills the entire job.
local ok, test_error = xpcall(run_test, debug.traceback)
if not ok then
  io.stderr:write("FAIL: Python provider headless test raised an error:\n", tostring(test_error), "\n")
  vim.cmd("cquit 1")
  return
end

vim.cmd("qa!")
