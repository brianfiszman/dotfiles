local M = {
  "lukas-reineke/indent-blankline.nvim",
  dependencies = {
    'HiPhish/rainbow-delimiters.nvim',
    {
      'echasnovski/mini.indentscope',
      version = '*',
      opt = {
        symbol = "│",
        options = { try_as_border = true },
      },
      init = function()
        vim.api.nvim_create_autocmd("FileType", {
          pattern = {
            "help",
            "alpha",
            "dashboard",
            "neo-tree",
            "Trouble",
            "trouble",
            "lazy",
            "mason",
            "notify",
            "toggleterm",
            "lazyterm",
          },
          callback = function()
            vim.b.miniindentscope_disable = true
          end,
        })
      end
    },
  },
  main = "ibl",
}

function M.config()
  local hooks = require "ibl.hooks"
  local icons = require "core.icons"
  local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
  }
  -- create the highlight groups in the highlight setup hook, so they are reset
  -- every time the colorscheme changes
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
  end)

  vim.g.rainbow_delimiters = { highlight = highlight }

  -- require("ibl").setup {
  --   indent = {
  --     char = "│",
  --     tab_char = "│",
  --   },
  --   scope = { enabled = false },
  --   exclude = {
  --     filetypes = {
  --       "help",
  --       "alpha",
  --       "dashboard",
  --       "neo-tree",
  --       "Trouble",
  --       "trouble",
  --       "lazy",
  --       "mason",
  --       "notify",
  --       "toggleterm",
  --       "lazyterm",
  --     },
  --   },
  -- }

  require("ibl").setup {
    scope = { enabled = true, highlight = highlight },
    exclude = {
      buftypes = { "terminal", "nofile" },
      filetypes = {
        "help",
        "startify",
        "dashboard",
        "lazy",
        "neogitstatus",
        "NvimTree",
        "Trouble",
        "text",
      }
    },
    indent = {
      char = icons.ui.LineMiddle,
    }
  }

  hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
end

return M
