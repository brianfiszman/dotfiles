local M = {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    -- general tests
    "vim-test/vim-test",
    "nvim-neotest/neotest-vim-test",
    -- language specific tests
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
    "nvim-neotest/neotest-jest",
    "nvim-neotest/neotest-go",
    "adrigzr/neotest-mocha",
    "rouge8/neotest-rust",
    "lawrence-laz/neotest-zig",
    "rcasia/neotest-bash",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-lua/plenary.nvim",
  },
}

function M.config()
  local wk = require "which-key"
  wk.register {
    ["<leader>tt"] = { "<cmd>lua require'neotest'.run.run()<cr>", "Test Nearest" },
    ["<leader>tw"] = { "<cmd>lua require('neotest').run.run({ jestCommand = 'jest --watch ' })<cr>", "Test Watch" },
    ["<leader>tf"] = { "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>", "Test File" },
    ["<leader>td"] = { "<cmd>lua require('neotest').run.run({strategy = 'dap'})<cr>", "Debug Test" },
    ["<leader>ts"] = { "<cmd>lua require('neotest').run.stop()<cr>", "Test Stop" },
    ["<leader>ta"] = { "<cmd>lua require('neotest').run.attach()<cr>", "Attach Test" },
  }


  ---@diagnostic disable: missing-fields
  require("neotest").setup {
    quickfix = {
      open = function()
        require("trouble").open({ mode = "quickfix", focus = false })
      end
    },
    discovery = {
      enabled = false,
    },
    status = { virtual_text = true },
    output = { open_on_run = true },
    adapters = {
      require "neotest-python" {
        dap = { justMyCode = false },
      },
      require "neotest-vitest",
      require "neotest-plenary",
      require "neotest-zig",
      require "neotest-go",
      require('neotest-mocha')({
        command = "yarn test:e2e",
        env = { CI = "true" },
        cwd = function()
          local file = vim.fn.expand('%:p')
          if string.find(file, "/packages/") then
            return string.match(file, "(.-/[^/]+/)src")
          end
          return vim.fn.getcwd()
        end
      }),
      -- require('neotest-jest')({
      --   jestCommand = "yarn test:e2e",
      --   jestConfigFile = "jest.config.js",
      --   env = { CI = "true" },
      --   cwd = function() return vim.fn.getcwd() end,
      -- }),
    },
  }
end

return M
