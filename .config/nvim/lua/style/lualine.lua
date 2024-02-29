local M = {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
}

function M.config()
  local lualine = require 'lualine'

  local colors = {
    blue        = '#80a0ff',
    transparent = '#00000000',
    darkBlue    = '#0087d7',
    cyan        = '#79dac8',
    black       = '#080808',
    white       = '#c6c6c6',
    red         = '#ff5189',
    crimson     = '#ec5f67',
    violet      = '#d183e8',
    purple      = '#5d4d7a',
    magenta     = '#d16d9e',
    grey        = '#303030',
  }

  local bubbles_theme = {
    normal = {
      a = { fg = colors.white, bg = colors.purple, gui = 'bold' },
      b = { fg = colors.white, bg = colors.grey },
      c = { fg = colors.white, bg = colors.transparent },
    },

    insert = { a = { fg = colors.transparent, bg = colors.purple, gui = 'bold' } },
    visual = { a = { fg = colors.transparent, bg = colors.purple, gui = 'bold,italic' } },
    replace = { a = { fg = colors.transparent, bg = colors.purple, gui = 'bold,italic' } },

    inactive = {
      a = { fg = colors.white, bg = colors.transparent },
      b = { fg = colors.white, bg = colors.transparent },
      c = { fg = colors.transparent, bg = colors.transparent },
    },
  }

  lualine.setup {
    options = {
      theme = bubbles_theme,
      component_separators = '|',
      section_separators = { left = '', right = '' },
      globalstatus = true,
    },
    sections = {
      lualine_a = {
        { 'mode', separator = { left = '' }, right_padding = 2 },
      },
      lualine_b = { 'filename', 'branch' },
      lualine_c = { 'fileformat' },
      lualine_x = {},
      lualine_y = { 'filetype', 'progress' },
      lualine_z = {
        { 'location', separator = { right = '' }, left_padding = 2 },
      },
    },
    inactive_sections = {
      lualine_a = { 'filename' },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { 'location' },
    },
    tabline = {},
    extensions = {},
  }
end

return M
