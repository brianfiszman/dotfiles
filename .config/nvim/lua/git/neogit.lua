local M = {
  "neogitorg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "lewis6991/gitsigns.nvim",
      tag = "release",
      config = true,
    },
    {
      'f-person/git-blame.nvim',
      opts = {}
    },
    { 'akinsho/git-conflict.nvim', version = "*", config = true },
    {
      'pwntester/octo.nvim',
      dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim', 'nvim-tree/nvim-web-devicons' },
      config = function() require "octo".setup() end
    },
  },
  event = "VeryLazy",
}

function M.config()
  local neogit = require 'neogit'
  local icons = require "core.icons"
  local wk = require "which-key"

  local function neogit_open() neogit.open({ kind = 'auto' }) end
  local function neogit_commit() neogit.status({ 'commit' }) end

  wk.register { ["<leader>gg"] = { neogit_open, "Neogit" } }
  wk.register { ["<leader>gc"] = { neogit_commit, "Neogit Commit" } }

  require("neogit").setup {
    auto_refresh = true,
    disable_builtin_notifications = false,
    use_magit_keybindings = false,
    -- Change the default way of opening neogit
    kind = "tab",
    -- Change the default way of opening the commit popup
    commit_popup = {
      kind = "split",
    },
    -- Change the default way of opening popups
    popup = {
      kind = "split",
    },
    -- customize displayed signs
    signs = {
      -- { CLOSED, OPENED }
      section = { icons.ui.ChevronRight, icons.ui.ChevronShortDown },
      item = { icons.ui.ChevronRight, icons.ui.ChevronShortDown },
      hunk = { "", "" },
    },
    integrations = { diffview = true }, -- adds integration with diffview.nvim
  }
end

return M
