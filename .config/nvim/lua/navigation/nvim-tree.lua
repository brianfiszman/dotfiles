local M = {}
M.load = {}

local icons = require "core.icons"

function open()
  vim.cmd('NvimTreeToggle<CR>')
end

function findFile()
  vim.cmd('NvimTreeFindFileToggle<CR>')
end

function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    if opts.desc then
      opts.desc = "keymaps.lua: " .. opts.desc
    end
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

function del(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    if opts.desc then
      opts.desc = "keymaps.lua: " .. opts.desc
    end
    options = vim.tbl_extend('force', options, opts)
  end
  vim.keymap.del(mode, lhs, rhs, options)
end

M.load.nvim_tree = function()
  -- this function is generated from `NvimTreeGenerateOnAttach`
  local function my_on_attach(bufnr)
    local api = require "nvim-tree.api"

    local function opts(desc)
      return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end


    local function opts_toggle(desc)
      return {
        desc = "nvim-tree: " .. desc,
        buffer = bufnr,
        noremap = true,
        silent = true,
        nowait = true,
        path =
        "<args>",
        update_root = "bang",
        find_file = true,
        focus = true
      }
    end

    -- default mappings
    api.config.mappings.default_on_attach(bufnr)

    -- custom mappings
    map('n', '<C-t>', api.node.open.tab, opts 'Open: New Tab')
    map('n', '<C-v>', api.node.open.vertical, opts 'Open: Vertical Split')
    map('n', '<C-x>', api.node.open.horizontal, opts 'Open: Horizontal Split')
    map('n', '<Tab>', api.node.open.preview, opts 'Open Preview')
    map('n', '<C-]>', api.tree.change_root_to_node, opts 'CD')
    --vim.keymap.set('n', '<C-e>', api.tree.toggle, opts)
    --vim.keymap.set('n', '<C-t>', api.tree.change_root_to_parent,        opts('Up'))
    --vim.keymap.set('n', '?',     api.tree.toggle_help,                  opts('Help'))
    del('n', '<C-e>', { buffer = bufnr })
    map('n', '<C-e>', api.tree.toggle, opts 'Open Toggle: Nvim Tree')

    -- del('n', '<leader>e>', { buffer = bufnr })
    map('n', '<leader>e', findFile, opts 'Find File Toggle: Nvim Tree')
    --    map('n', '<leader>e', api.tree.toggle, opts_toggle 'Open Toggle: Nvim Tree')
    --keymap('n', '<C-e>', '<cmd>NvimTreeFindFileToggle<CR>', { noremap = true, silent = true })
    --keymap('n', '<C-e>', '<cmd>NvimTreeRefresh<CR>', { noremap = true, silent = true })
  end

  require("nvim-tree").setup({
    on_attach = my_on_attach,
    auto_reload_on_write = true,
    update_cwd = true,
    -- Integration for Project.nvim --
    sync_root_with_cwd = true,
    hijack_netrw = true,
    hijack_cursor = true,
    respect_buf_cwd = true,
    update_focused_file = {
      enable = true,
      debounce_delay = 15,
      update_root = true
    },
    ----------------------------------
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
      signcolumn = 'yes',
    },
    filesystem_watchers = {
      enable = true,
    },
    renderer = {
      add_trailing = false,
      group_empty = false,
      highlight_git = false,
      full_name = false,
      highlight_opened_files = "none",
      root_folder_label = ":t",
      indent_width = 2,
      indent_markers = {
        enable = false,
        inline_arrows = true,
        icons = {
          corner = "└",
          edge = "│",
          item = "│",
          none = " ",
        },
      },
      icons = {
        git_placement = "before",
        padding = " ",
        symlink_arrow = " ➛ ",
        glyphs = {
          default = icons.ui.Text,
          symlink = icons.ui.FileSymlink,
          bookmark = icons.ui.BookMark,
          folder = {
            arrow_closed = icons.ui.ChevronRight,
            arrow_open = icons.ui.ChevronShortDown,
            default = icons.ui.Folder,
            open = icons.ui.FolderOpen,
            empty = icons.ui.EmptyFolder,
            empty_open = icons.ui.EmptyFolderOpen,
            symlink = icons.ui.FolderSymlink,
            symlink_open = icons.ui.FolderOpen,
          },
          git = {
            unstaged = icons.git.FileUnstaged,
            staged = icons.git.FileStaged,
            unmerged = icons.git.FileUnmerged,
            renamed = icons.git.FileRenamed,
            untracked = icons.git.FileUntracked,
            deleted = icons.git.FileDeleted,
            ignored = icons.git.FileIgnored,
          },
        },
      },
      special_files = { "Cargo.toml", "Makefile", "README.md", "readme.md" },
      symlink_destination = true,
    },
    diagnostics = {
      enable = true,
      icons = {
        hint = icons.diagnostics.BoldHint,
        info = icons.diagnostics.BoldInformation,
        warning = icons.diagnostics.BoldWarning,
        error = icons.diagnostics.BoldError,
      },
      show_on_dirs = true,
      show_on_open_dirs = false,
      debounce_delay = 50,
    }
  })

  map('n', '<C-e>', open, { noremap = true, silent = true })
  map('n', '<leader>e', findFile, { noremap = true, silent = true })
end

M.load.nvim_tree()

return M
