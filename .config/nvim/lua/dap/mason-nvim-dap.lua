local M = {
  "jay-babu/mason-nvim-dap.nvim",
  dependencies = {
    -- One lazy trigger owns the whole debug stack. Load DAP first so dependent
    -- plugin setup callbacks can safely require it.
    require "dap.nvim-dap",
    require "dap.nvim-dap-ui",
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = {},
    },
    {
      "folke/which-key.nvim",
      optional = true,
      opts = {
        defaults = {
          ["<leader>D"] = { name = "+debug" },
        },
      },
    },
    "williamboman/mason.nvim",
  },
  -- Keep the native command API lazy-loadable too, not just the keymaps.
  cmd = {
    "DapSetLogLevel",
    "DapShowLog",
    "DapContinue",
    "DapToggleBreakpoint",
    "DapClearBreakpoints",
    "DapToggleRepl",
    "DapStepOver",
    "DapStepInto",
    "DapStepOut",
    "DapPause",
    "DapTerminate",
    "DapDisconnect",
    "DapRestartFrame",
    "DapNew",
    "DapEval",
    -- mason-nvim-dap registers these from its setup(), so they must be lazy
    -- triggers too or they are unavailable until another DAP action runs.
    "DapInstall",
    "DapUninstall",
  },
  keys = {
    { "<leader>DB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
    { "<leader>Db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>Dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>Da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
    { "<leader>DC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>Dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
    { "<leader>Di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>Dj", function() require("dap").down() end, desc = "Down" },
    { "<leader>Dk", function() require("dap").up() end, desc = "Up" },
    { "<leader>Dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>Do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>DO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>Dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>Dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>Ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>Dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>Dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    {
      "<leader>da",
      function()
        -- Keep the existing Run with Args behavior tracked separately in #40.
        require("dap").continue()
      end,
      desc = "Run with Args",
    },
    { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
    { "<leader>dk", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint", mode = { "n", "v" } },
  },
}

function M.config()
  local dap = require("dap")
  local dap_utils = require("dap.utils")
  local ts_adapters = require("dap.languages.typescript")
  local js_based_languages = {
    "javascript",
    "typescript",
    "typescriptreact",
    "javascriptreact",
  }

  -- The TypeScript adapter resolves its executable through Mason's registry.
  -- Lazy replays a command trigger as soon as this config returns. Ensure
  -- the registry is available first so :DapInstall can resolve its arguments
  -- on a clean machine during that very first invocation.
  require("mason-registry").refresh()

  ts_adapters.setAdapters(js_based_languages, dap, dap_utils)

  local mason_nvim_dap = require("mason-nvim-dap")
  mason_nvim_dap.setup({
    automatic_installation = true,
    -- These are mason-nvim-dap source identifiers, not filetype names.
    -- The legacy node2 source maps to node-debug2-adapter, which is no longer
    -- present in the current Mason registry. TypeScript uses the maintained
    -- js-debug-adapter source through the custom pwa-node/pwa-chrome adapters.
    ensure_installed = { "delve", "codelldb", "js", "python", "dart" },
  })

  require("dap.ext.vscode").load_launchjs(nil, {
    ["pwa-node"] = js_based_languages,
    ["node"] = js_based_languages,
    ["chrome"] = js_based_languages,
    ["pwa-chrome"] = js_based_languages,
  })
end

return M
