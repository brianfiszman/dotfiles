local M = {}

function M.setAdapters(js_based_languages)
  local dap_utils = require("dap.utils")
  local dap = require("dap")

  for _, language in ipairs(js_based_languages) do
    dap.configurations[language] = {
      -- Debug single nodejs files
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require 'dap.utils'.pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch Current File (pwa-node)",
        cwd = vim.fn.getcwd(),
        args = { "${file}" },
        sourceMaps = true,
        protocol = "inspector",
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch Current File (pwa-node with ts-node)",
        cwd = vim.fn.getcwd(),
        runtimeArgs = { "--loader", "ts-node/esm" },
        runtimeExecutable = "node",
        args = { "${file}" },
        sourceMaps = true,
        protocol = "inspector",
        skipFiles = { "<node_internals>/**", "node_modules/**" },
        resolveSourceMapLocations = {
          "${workspaceFolder}/**",
          "!**/node_modules/**",
        },
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Launch Test Current File (pwa-node with vitest)",
        cwd = vim.fn.getcwd(),
        program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
        args = { "--inspect-brk", "--threads", "false", "run", "${file}" },
        autoAttachChildProcesses = true,
        smartStep = true,
        console = "integratedTerminal",
        skipFiles = { "<node_internals>/**", "node_modules/**" },
      },
      {
        type = "pwa-chrome",
        request = "attach",
        name = "Attach Program (pwa-chrome, select port)",
        program = "${file}",
        cwd = vim.fn.getcwd(),
        sourceMaps = true,
        port = function()
          return vim.fn.input("Select port: ", 9222)
        end,
        webRoot = "${workspaceFolder}",
      },
      -- {
      --   type = "node2",
      --   request = "attach",
      --   name = "Attach Program (Node2)",
      --   processId = dap_utils.pick_process,
      -- },
      -- {
      --   type = "node2",
      --   request = "attach",
      --   name = "Attach Program (Node2 with ts-node)",
      --   cwd = vim.fn.getcwd(),
      --   sourceMaps = true,
      --   skipFiles = { "<node_internals>/**" },
      --   port = 9229,
      -- },
      {
        type = "pwa-node",
        request = "attach",
        name = "Attach Program (pwa-node, select pid)",
        cwd = vim.fn.getcwd(),
        processId = dap_utils.pick_process,
        skipFiles = { "<node_internals>/**" },
      },
      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Mocha Tests",
        -- trace = true, -- include debugger info
        runtimeExecutable = "node",
        runtimeArgs = {
          "./node_modules/mocha/bin/mocha.js",
        },
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },

      {
        type = "pwa-node",
        request = "launch",
        name = "Debug Jest Tests",
        -- trace = true, -- include debugger info
        runtimeExecutable = "node",
        runtimeArgs = {
          "./node_modules/jest/bin/jest.js",
          "--runInBand",
        },
        rootPath = "${workspaceFolder}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        internalConsoleOptions = "neverOpen",
      },
      -- Divider for the launch.json derived configs
      {
        name = "----- ↓ launch.json configs ↓ -----",
        type = "",
        request = "launch",
      },
    }
  end
end

return M
