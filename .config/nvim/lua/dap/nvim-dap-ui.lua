-- The UI is loaded as part of the DAP stack. Its key triggers are owned by
-- dap.mason-nvim-dap so every debugger action loads the complete integration.
local M = {
  "rcarriga/nvim-dap-ui",
  dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  opts = {},
}

function M.config(_, opts)
  -- Setup DAP UI after the core nvim-dap dependency is available.
  local dap = require("dap")
  local dapui = require("dapui")
  dapui.setup(opts)
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open({})
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close({})
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close({})
  end

  vim.fn.sign_define("DapBreakpoint", {
    text = "🔴",
    texthl = "DapBreakpointSymbol",
    linehl = "DapBreakpoint",
    numhl = "DapBreakpoint",
  })
  vim.fn.sign_define("DapStopped", {
    text = "➡️",
    texthl = "DapStoppedSymbol",
    linehl = "DapBreakpoint",
    numhl = "DapBreakpoint",
  })
end

return M
