local M = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    -- Additional text objects for treesitter
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  build = ":TSUpdate",
}


function M.config()
  require 'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = { "c", "lua", "luadoc", "go", "javascript", "typescript", "json", "json5", "jsdoc", "yaml", "xml", "vim", "vimdoc", "tsx", "scheme", "make", "dot", "dockerfile", "csv", "diff", "gitignore", "gitcommit", "git_config", "git_rebase", "gitattributes", "css", "comment", "gomod", "gosum", "gowork", "html", "ini", "markdown", "markdown_inline", "passwd", "proto", "scss", "sql" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    indent = {
      enable = true
    },

    highlight = {
      -- `false` will disable the whole extension
      enable = true,
      disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,

      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = true,
      use_languagetree = true,
    },
    refactor = {
      highlight_definitions = { enable = true },
      highlight_current_scope = { enable = false },
    },
    rainbow = {
      enable = true,
      -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
      extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
      -- colors = {}, -- table of hex strings
      -- termcolors = {} -- table of colour name strings
    },
    autotag = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<leader>V',
        node_incremental = '<leader>V',
        scope_incremental = false,
        node_decremental = '<bs>'
      }
    }
  }
end

return M
