local M = {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
    { 'akinsho/git-conflict.nvim', version = "*", config = true },
    {
      "lewis6991/gitsigns.nvim",
      tag = "release",
      config = true,
    },
    {
      'f-person/git-blame.nvim',
      opts = {}
    },
    {
      "folke/which-key.nvim",
      optional = true,
      opts = {
        defaults = {
          ["<leader>g"] = { name = "+LazyGit" },
        },
      },
    },
  },

  event = "VeryLazy",
}

function M.config()
  local wk = require "which-key"
  wk.register({
    ["<leader>gg"] = { "<cmd>LazyGit<cr>", "LazyGit" },
  }, { mode = "n" })


  vim.g.lazygit_floating_window_use_plenary = 1 -- use plenary.nvim to manage floating window if available

  require('telescope').load_extension('lazygit')
end

return M
