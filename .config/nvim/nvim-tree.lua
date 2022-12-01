-- examples for your init.lua

-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true
vim.keymap.set('n', '<C-e>', ':NvimTreeToggle<CR>')

require'nvim-web-devicons'.get_icons()
-- OR setup with some options
require("nvim-tree").setup({
    auto_reload_on_write = true,
    sync_root_with_cwd = true,
    git = {
      enable = true,
      ignore = true,
      show_on_dirs = true,
      timeout = 4000,
    },
    actions = {
      open_file = {
        quit_on_open = true,
        window_picker = {
          enable = false,
          chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
          exclude = {
            filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
            buftype = { "nofile", "terminal", "help" },
          },
        },
      },
    },
    view = {
      adaptive_size = true,
      mappings = {
        list = {
          { key = '<C-e>', action = "" },
          { key = '<C-r>', action = "refresh" },
          { key = '<C-t>', action = "" },
        },
      },
    },
    renderer = {
      group_empty = true,
      highlight_git = true,
      icons = {
        show = {
          git = true,
        },
      },
    },
  })

require'nvim-web-devicons'.setup {
  -- your personnal icons can go here (to override)
  -- you can specify color or cterm_color instead of specifying both of them
  -- DevIcon will be appended to `name`
  override = {
    zsh = {
      icon = "",
      color = "#428850",
      cterm_color = "65",
      name = "Zsh"
    }
  };
  -- globally enable different highlight colors per icon (default to true)
  -- if set to false all icons will have the default icon's color
  color_icons = true;
  -- globally enable default icons (default to false)
  -- will get overriden by `get_icons` option
  default = true;
}
