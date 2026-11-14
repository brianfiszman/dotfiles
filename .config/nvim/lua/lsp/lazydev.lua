return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    integrations = {
      lspconfig = true,
      cmp = true,
    },
    library = {
      -- Preserve the existing plugin API type libraries.
      "neotest",
      "nvim-dap-ui",
      "nvim-treesitter",
      "plenary.nvim",
      "telescope.nvim",
    },
  },
}
