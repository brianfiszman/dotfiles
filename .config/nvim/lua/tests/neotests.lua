-- Resolve Jest configuration with libuv only. The pinned neotest-jest
-- default calls vim.fn.glob() from an async fast-event context (E5560).
-- Keep the adapter's nearest-ancestor lookup and TypeScript preference.
local function find_jest_config(path)
  local uv = vim.uv
  local resolved_path = uv.fs_realpath(path) or path
  local path_stat = uv.fs_stat(resolved_path)
  local directory = path_stat and path_stat.type == "directory"
      and resolved_path
    or vim.fs.dirname(resolved_path)

  while directory do
    local ts_config = vim.fs.joinpath(directory, "jest.config.ts")
    local js_config = vim.fs.joinpath(directory, "jest.config.js")
    local ts_stat = uv.fs_stat(ts_config)
    local js_stat = uv.fs_stat(js_config)

    if ts_stat and ts_stat.type == "file" then
      return ts_config
    end
    if js_stat and js_stat.type == "file" then
      return js_config
    end

    local parent = vim.fs.dirname(directory)
    if not parent or parent == directory then
      break
    end
    directory = parent
  end
end

local M = {
  "nvim-neotest/neotest",
  lazy = true,
  keys = {
    { "<leader>tt", desc = "Test Nearest" },
    { "<leader>tw", desc = "Test Watch" },
    { "<leader>tf", desc = "Test File" },
    { "<leader>td", desc = "Debug Test" },
    { "<leader>ts", desc = "Test Stop" },
    { "<leader>ta", desc = "Attach Test" },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/nvim-nio",
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
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
    "nvim-neotest/neotest-jest",
    "nvim-neotest/neotest-go",
    "adrigzr/neotest-mocha",
    "rouge8/neotest-rust",
    "lawrence-laz/neotest-zig",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-lua/plenary.nvim",
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
    -- Debug Test is the explicit exception that loads the lazy DAP stack.
    ["<leader>td"] = { "<cmd>lua require('lazy').load({ plugins = { 'mason-nvim-dap.nvim' } }); require('neotest').run.run({strategy = 'dap'})<cr>", "Debug Test" },
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
      require "neotest-plenary",
      require "neotest-zig",
      require "neotest-go",
      -- Each adapter discovers its runner and configuration in the workspace.
      -- Neotest is used across unrelated projects; do not hard-code this repo's
      -- yarn scripts or a non-existent config file.
      require("neotest-mocha")({}),
      require("neotest-jest")({
        -- The upstream default uses vim.fn.glob() in build_spec's fast event.
        jestConfigFile = find_jest_config,
      }),
    },
  }
end

return M
