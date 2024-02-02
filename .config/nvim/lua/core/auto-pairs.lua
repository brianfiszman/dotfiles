local M = {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  dependencies = { 'windwp/nvim-ts-autotag', 'nvim-treesitter/nvim-treesitter' },
  lazy = true,
}

M.config = function()
  require("nvim-autopairs").setup {
    check_ts = true,
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
  }
end

return M
