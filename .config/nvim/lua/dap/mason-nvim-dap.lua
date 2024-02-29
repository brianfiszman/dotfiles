local M = {
  "jay-babu/mason-nvim-dap.nvim",
  opts = {},
  dependencies = {
    require "dap.vscode-js-debugger",
    require "dap.nvim-dap",
    {
      "williamboman/mason.nvim",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        table.insert(opts.ensure_installed, "js-debug-adapter")
      end,
    },
    "mxsdev/nvim-dap-vscode-js",
  },
}

function M.config()
  local dap = require 'dap'
  local dap_utils = require 'dap.utils'
  local tsAdapters = require 'dap.languages.typescript'
  local js_based_languages = { 'javascript', 'typescript', 'typescriptreact', 'javascriptreact' }

  tsAdapters.setAdapters(js_based_languages, dap, dap_utils)


  require("mason-nvim-dap").setup({
    automatic_installation = true,
    ensure_installed = { "go", "rust", "delve", "node2", "js", "python", "typescript", "typescriptreact", "javascript", "javascriptreact", "vue", "dart" },
    cmd = { "DapInstall", "DapUninstall" },
  })

  -- VSCODE JS (Node/Chrome/Terminal/Jest)
  require("dap-vscode-js").setup({
    debugger_path = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"),
    adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
  })

  require('dap.ext.vscode').load_launchjs(nil,
    {
      ['pwa-node'] = js_based_languages,
      ['node'] = js_based_languages,
      ['chrome'] = js_based_languages,
      ['pwa-chrome'] = js_based_languages
    }
  )
end

return M
