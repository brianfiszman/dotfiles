-- fancy UI for the debugger

local M = {
  "rcarriga/nvim-dap-ui",
  -- stylua: ignore

  keys = {
    { "<leader>du", function() require("dapui").toggle({}) end,        desc = "Dap UI" },
    { "<leader>de", function() require("dapui").eval() end,            desc = "Eval",              mode = { "n", "v" } },
    { '<leader>dk', function() require('dap').continue() end,          desc = "Continue" },
    { '<leader>dl', function() require('dap').run_last() end,          desc = "Run Last" },
    { '<leader>b',  function() require('dap').toggle_breakpoint() end, desc = "Toggle Breakpoint", mode = { "n", "v" } },
  },
  opts = {},
}

function M.config(_, opts)
  -- setup dap config by VsCode launch.json file
  -- require("dap.ext.vscode").load_launchjs()
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
end

return M
