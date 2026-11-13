local M = {
  "mfussenegger/nvim-dap",
}

function M.config()
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
end

return M
