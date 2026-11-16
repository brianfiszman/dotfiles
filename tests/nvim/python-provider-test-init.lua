local config_dir = vim.env.DOTFILES_NVIM_CONFIG
assert(config_dir and config_dir ~= "", "DOTFILES_NVIM_CONFIG must point to the installed Neovim config")
vim.opt.rtp:prepend(config_dir)

local provider = require("core.python-provider")
provider.configure_host()
provider.setup()

local test_script = vim.env.DOTFILES_NVIM_TEST_SCRIPT
assert(test_script and test_script ~= "", "DOTFILES_NVIM_TEST_SCRIPT must point to a provider test")
dofile(test_script)

vim.cmd("qa!")
