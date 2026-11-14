return {
  "mason-org/mason-lspconfig.nvim",
  branch = "main",
  dependencies = {
    {
      "mason-org/mason.nvim",
      branch = "main",
      opts = {},
    },
    {
      "neovim/nvim-lspconfig",
      branch = "master",
    },
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
    "pmizio/typescript-tools.nvim",
    "folke/neodev.nvim",
    "nvimdev/lspsaga.nvim",
    "onsails/lspkind.nvim",
    "ray-x/lsp_signature.nvim",
  },
  config = function()
    require("lsp.config").setup()
  end,
}
