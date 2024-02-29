local M = {
  "mfussenegger/nvim-dap",
  dependencies = {
    require "dap.nvim-dap-ui",
    -- virtual text for the debugger
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },

    -- which key integration
    {
      "folke/which-key.nvim",
      optional = true,
      opts = {
        defaults = {
          ["<leader>D"] = { name = "+debug" },
        },
      },
    },
  },
  keys = {
    { "<leader>DB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<leader>Db", function() require("dap").toggle_breakpoint() end,                                    desc = "Toggle Breakpoint" },
    { "<leader>Dc", function() require("dap").continue() end,                                             desc = "Continue" },
    { "<leader>Da", function() require("dap").continue({ before = get_args }) end,                        desc = "Run with Args" },
    { "<leader>DC", function() require("dap").run_to_cursor() end,                                        desc = "Run to Cursor" },
    { "<leader>Dg", function() require("dap").goto_() end,                                                desc = "Go to line (no execute)" },
    { "<leader>Di", function() require("dap").step_into() end,                                            desc = "Step Into" },
    { "<leader>Dj", function() require("dap").down() end,                                                 desc = "Down" },
    { "<leader>Dk", function() require("dap").up() end,                                                   desc = "Up" },
    { "<leader>Dl", function() require("dap").run_last() end,                                             desc = "Run Last" },
    { "<leader>Do", function() require("dap").step_out() end,                                             desc = "Step Out" },
    { "<leader>DO", function() require("dap").step_over() end,                                            desc = "Step Over" },
    { "<leader>Dp", function() require("dap").pause() end,                                                desc = "Pause" },
    { "<leader>Dr", function() require("dap").repl.toggle() end,                                          desc = "Toggle REPL" },
    { "<leader>Ds", function() require("dap").session() end,                                              desc = "Session" },
    { "<leader>Dt", function() require("dap").terminate() end,                                            desc = "Terminate" },
    { "<leader>Dw", function() require("dap.ui.widgets").hover() end,                                     desc = "Widgets" },
    {
      "<leader>da",
      function()
        -- if vim.fn.filereadable(".vscode/launch.json") then
        --   local dap_vscode = require("dap.ext.vscode")
        --   dap_vscode.load_launchjs(nil, {
        --     ["pwa-node"] = js_based_languages,
        --     ["chrome"] = js_based_languages,
        --     ["pwa-chrome"] = js_based_languages,
        --   })
        -- end
        require("dap").continue()
      end,
      desc = "Run with Args",
    },
  },
}

function M.config()
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
end

return M
