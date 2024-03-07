local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'HiPhish/rainbow-delimiters.nvim',
    {
      'echasnovski/mini.indentscope',
      event = { 'BufReadPre', 'BufNewFile' },
      version = '*',
      opts = function()
        return {
          draw = {
            delay = 100,
          },
          options = { try_as_border = true, },
          symbol = "│",
        }
      end,
      init = function()
        vim.api.nvim_create_autocmd("FileType", {
          pattern = EXCLUDES_BUFFTYPES,
          callback = function()
            vim.b.miniindentscope_disable = true
          end,
        })
      end,
    },
  },
  main = "ibl",
}


EXCLUDES_BUFFTYPES = {
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
  "help",
  "startify",
  "dashboard",
  "lazy",
  "neogitstatus",
  "NvimTree",
  "Trouble",
  "text",
}

function M.config()
  local hooks = require "ibl.hooks"
  local highlight = {
    "CursorColumn",
    "Whitespace",
  }

  local rb_highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
  }

  local rainbow_delimiters = require "rainbow-delimiters"

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

  require("ibl").setup {
    indent = { highlight = highlight, char = "", tab_char = "", },
    exclude = {
      buftypes = { "terminal", "nofile" },
      filetypes = EXCLUDES_BUFFTYPES
    },
    whitespace = {
      highlight = highlight,
      remove_blankline_trail = false,
    },
    scope = { enabled = false },
  }

  require('rainbow-delimiters.setup').setup {
    strategy = {
      [''] = rainbow_delimiters.strategy['global'],
      vim = rainbow_delimiters.strategy['local'],
    },
    query = {
      [''] = 'rainbow-delimiters',
      lua = 'rainbow-blocks',
    },
    highlight = rb_highlight,
  }


  hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
end

return M
