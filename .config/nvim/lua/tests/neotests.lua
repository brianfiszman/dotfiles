local M = {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    -- general tests
    {
      "vim-test/vim-test",
      opts = {
        setup = {},
      },
      config = function(plugin, opts)
        vim.g["test#strategy"] = "neovim"
        vim.g["test#neovim#term_position"] = "belowright"
        vim.g["test#neovim#preserve_screen"] = 1

        -- Set up vim-test
        for k, _ in pairs(opts.setup) do
          opts.setup[k](plugin, opts)
        end
      end,
    },
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
    "mfussenegger/nvim-dap"
  },
}

function M.config()
  local wk = require "which-key"
  local neotest_ns = vim.api.nvim_create_namespace("neotest")
  vim.diagnostic.config({
    virtual_text = {
      format = function(diagnostic)
        -- Replace newline and tab characters with space for more compact diagnostics
        local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
        return message
      end,
    },
  }, neotest_ns)

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
    icons = {
      passed = "",
      running = "",
      failed = "",
      skipped = "",
      unknown = "",
      child_indent = "│",
      child_prefix = "├",
      collapsed = "",
      expanded = "",
      final_child_indent = " ",
      final_child_prefix = "╰",
      non_collapsed = "",
      watching = "",
      running_animated = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
    },
    status = { virtual_text = true },
    output = { open_on_run = true },
    log_level = 3,
    adapters = {
      require("neotest-vim-test")({
        ignore_file_types = { "python", "vim", "lua" },
      }),
      require "neotest-python" {
        dap = { justMyCode = false },
      },
      require "neotest-vitest",
      require "neotest-plenary",
      require "neotest-zig",
      require "neotest-go",
      require('neotest-mocha')({
        command = "yarn test:neovim",
        env = { CI = true },
        cwd = function() return vim.fn.getcwd() end,
      }),
      require('neotest-jest')({
        jestCommand = "yarn test --silent",
        jestConfigFile = "scripts/vscode-mocharc.yml",
        env = { CI = true },
        cwd = function() return vim.fn.getcwd() end,
      }),
    },
  }
end

return M
