local js_based_languages = {
  "typescript",
  "javascript",
  "typescriptreact",
  "javascriptreact",
  "vue",
}

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
    {
      "mxsdev/nvim-dap-vscode-js",
      dependencies = {
        "microsoft/vscode-js-debug",
        version = "1.x",
        build = "npm i && npm run compile vsDebugServerBundle && mv dist out"
      },
      -- After install, build it and rename the dist directory to out
      config = function()
        require("dap-vscode-js").setup({
          node_path = 'node',
          debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
          adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
        })
      end
    }
    --    require "dap.dap-vscode-js",
    -- require 'dap.mason-nvim-dap',
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
  require 'dap.languages.typescript'.setAdapters(js_based_languages)

  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
end

return M
