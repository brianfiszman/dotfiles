local M = {
  "jay-babu/mason-nvim-dap.nvim",
}

function M.config()
  local adapters = require "dap.adapters"

  -- Configure adapters
  M = adapters.config(M)

  require("mason-nvim-dap").setup({
    automatic_installation = true,
    ensure_installed = { "go", "rust", "delve" },
    cmd = { "DapInstall", "DapUninstall" },
  })
end

return M
