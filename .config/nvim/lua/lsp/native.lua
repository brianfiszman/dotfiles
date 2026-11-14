return {
  "mason-org/mason-lspconfig.nvim",
  branch = "main",
  dependencies = {
    {
      "mason-org/mason.nvim",
      branch = "main",
      opts = {
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      },
    },
    {
      "neovim/nvim-lspconfig",
      branch = "master",
    },
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "folke/neodev.nvim",
    "nvimdev/lspsaga.nvim",
    "onsails/lspkind.nvim",
    "ray-x/lsp_signature.nvim",
  },
  config = function()
    require("lsp.config").setup()
  end,
}
