require("core.lazy-maintenance").setup()

require("lazy").setup({
  {
    'ryanoasis/powerline-extra-symbols',
    'nvim-lua/plenary.nvim',
  },
  -- SNIPPETS --
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      'SergioRibera/cmp-dotenv',
      'L3MON4D3/LuaSnip',
      'rafamadriz/friendly-snippets',
      'saadparwaiz1/cmp_luasnip',
      "lukas-reineke/cmp-under-comparator",
      "nvim-treesitter/nvim-treesitter",
      "petertriho/cmp-git",
    },
  },
  {
    'Joakker/lua-json5',
    build = './install.sh',
    config = function() table.insert(vim._so_trails, "/?.dylib") end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    build = "make install_jsregexp",
    config = function() require 'snippets.luasnip' end
  },
  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    -- Go's bundled textobject hook still targets nvim-treesitter.configs.
    -- The standalone current-API integration is configured by treesitter.lua.
    config = function() require("go").setup({ textobjects = false }) end,
    -- Load Go tooling only for Go source and module files, not every command line.
    ft = { "go", 'gomod' },
    -- Optional Go helper binaries are installed on demand, not during every plugin restore.
  },
  {
    "catppuccin/nvim",
    dependencies = { 'navarasu/onedark.nvim' },
    name = "catppuccin",
    priority = 1000,
    config = function() require 'style.colorscheme' end
  },
  {
    'nvim-tree/nvim-web-devicons',
    config = function()
      require 'style.nvim-web-devicons'
      require 'style.devicons'
    end
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function() require "navigation.bufferline" end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function() require 'navigation/nvim-tree' end,
  },
  {
    "folke/trouble.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function() require "troubleshoot.trouble" end,
  },
  -- Which-key
  {
    'folke/which-key.nvim',
    lazy = true,
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("which-key").setup()
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = true
  },
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    config = true,
  },
  {
    "nvim-neorg/neorg",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neorg/tree-sitter-norg",
      "nvim-neorg/tree-sitter-norg-meta",
    },
    config = function()
      -- Neorg's LuaRocks parsers live outside the default runtimepath.
      -- Expose them before Neorg checks for and initializes its grammars.
      local data_dir = vim.fn.stdpath("data")
      for _, parser in ipairs({ "tree-sitter-norg", "tree-sitter-norg-meta" }) do
        local parser_runtime = data_dir .. "/lazy-rocks/" .. parser .. "/lib/lua/5.1"
        if vim.fn.isdirectory(parser_runtime) == 1 then
          vim.opt.runtimepath:prepend(parser_runtime)
        end
      end

      require("neorg").setup {
        load = {
          ["core.defaults"] = {},  -- Loads default behaviour
          ["core.concealer"] = {}, -- Adds pretty icons to your documents
          ["core.dirman"] = {      -- Manages Neorg workspaces
            config = {
              workspaces = {
                notes = "~/Documents/Notes/",
              },
            },
          },
        },
      }
    end,
  },
  {
    'b0o/incline.nvim',
    opts = {},
    -- Optional: Lazy load Incline
    event = 'VeryLazy',
  },
  {
    "tiagovla/scope.nvim",
    -- Scope owns tab-local buffer behavior independently of Telescope.
    -- Its Telescope extension is registered when the first picker is opened.
    config = function()
      require("scope").setup()
    end,
  },
  {
    'yamatsum/nvim-cursorline',
    opts = {}
  },
  "mg979/vim-visual-multi",
  --- LSP ---
  require "lsp.native",
  require "lsp.lazydev",
  --- CORE ---
  require 'core.auto-pairs',
  require 'core.toggleterm',
  require 'core.schemastore',
  require 'core.colorizer',
  require 'core.notify',
  require 'treesitter',
  require 'style.lualine',
  require 'style.indentline',
  require 'bindings.comment',
  require 'git.lazygit',
  require 'tests.neotests',
  require 'navigation.neoscroll',
  require 'navigation.project',
  require 'navigation.alpha',
  require 'navigation.telescope',
  require 'navigation.dressing',
  require 'navigation.noice',
  require 'dap.mason-nvim-dap',
  require 'linting.nvim-lint',
  require 'formatting.conform',
  require 'ai.avante',
}, {
  -- system luarocks is Lua 5.5; neorg's rocks need 5.1, so let lazy
  -- bootstrap its own toolchain
  rocks = { hererocks = true },
})
