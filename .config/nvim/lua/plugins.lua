require("lazy").setup({
  {
    'ryanoasis/powerline-extra-symbols',
    'yuttie/comfortable-motion.vim',
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
      'Exafunction/codeium.vim',
    },
  },
  {
    'Joakker/lua-json5',
    build = './install.sh',
    config = function() table.insert(vim._so_trails, "/?.dylib") end,
  },
  {
    "microsoft/vscode-js-debug",
    opt = {},
    build = "npm i --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out"
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
    config = function() require("go").setup() end,
    event = { "CmdlineEnter" },
    ft = { "go", 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
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
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      -- Additional text objects for treesitter
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = ":TSUpdate",
    config = function() require 'treesitter' end
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
    build = ":Neorg sync-parsers",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
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
    'Exafunction/codeium.vim',
    event = 'BufEnter',
    config = function() require 'ai.codeium' end
  },
  {
    'b0o/incline.nvim',
    opts = {},
    -- Optional: Lazy load Incline
    event = 'VeryLazy',
  },
  {
    "tiagovla/scope.nvim",
    dependencies = { 'telescope.nvim' },
    config = function()
      require "scope".setup()
      require 'telescope'.load_extension('scope')
    end
  },
  {
    'yamatsum/nvim-cursorline',
    opts = {}
  },
  {
    'echasnovski/mini.animate',
    version = '*',
    opts = function()
      -- don't use animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs({ "up", "down" }) do
        local key = "<scrollwheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      local animate = require("mini.animate")
      return {
        resize = {
          timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      }
    end,
  },
  "mg979/vim-visual-multi",
  --- LSP ---
  require "lsp.lsp-zero",
  --- CORE ---
  require 'core.auto-pairs',
  require 'core.toggleterm',
  require 'core.schemastore',
  require 'core.colorizer',
  require 'core.notify',
  require 'style.lualine',
  require 'style.indentline',
  require 'bindings.comment',
  require 'git.neogit',
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
})
