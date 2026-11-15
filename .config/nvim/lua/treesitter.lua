local legacy_treesitter_commit = "85168f15808d89b0222313652b9d2777eda3cb08"
local compat_patch = "patches/nvim-treesitter-neovim-0.12.patch"

local function patch_legacy_treesitter_for_nvim_012(plugin)
  -- The init hook also runs before a fresh lazy.nvim install has cloned the
  -- plugin. In that case the build hook below applies the patch after cloning.
  if vim.fn.isdirectory(plugin.dir) ~= 1 then
    return
  end

  local result = vim.system({
    "git", "-C", plugin.dir, "rev-parse", "HEAD",
  }, { text = true }):wait()
  if result.code ~= 0 then
    error("Could not inspect the nvim-treesitter revision: " .. (result.stderr or "unknown error"))
  end

  local head = (result.stdout or ""):gsub("%s+$", "")
  if head ~= legacy_treesitter_commit then
    error(("Refusing to patch unexpected nvim-treesitter revision: %s"):format(head))
  end

  local patch = vim.fn.stdpath("config") .. "/" .. compat_patch
  local check = vim.system({
    "git", "-C", plugin.dir, "apply", "--check", patch,
  }, { text = true }):wait()

  if check.code == 0 then
    local applied = vim.system({
      "git", "-C", plugin.dir, "apply", patch,
    }, { text = true }):wait()
    if applied.code ~= 0 then
      error("Could not apply the nvim-treesitter Neovim 0.12 compatibility patch: "
        .. (applied.stderr or "unknown error"))
    end
    return
  end

  local reverse = vim.system({
    "git", "-C", plugin.dir, "apply", "--reverse", "--check", patch,
  }, { text = true }):wait()
  if reverse.code ~= 0 then
    error("nvim-treesitter Neovim 0.12 compatibility patch does not apply cleanly: "
      .. (check.stderr or check.stdout or "unknown patch error"))
  end
end

local M = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    -- Additional text objects for treesitter
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  -- lazy.nvim runs init on every startup, so already-installed checkouts get
  -- patched before any Treesitter module loads. The build hook covers fresh
  -- installs after clone; both paths are safe to repeat.
  init = vim.fn.has("nvim-0.12") == 1 and patch_legacy_treesitter_for_nvim_012 or nil,
  -- Keep the original build path on 0.11. ensure_installed handles configured parsers.
  build = vim.fn.has("nvim-0.12") == 1 and patch_legacy_treesitter_for_nvim_012 or ":TSUpdate",
}


function M.config()
  require 'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all"
    ensure_installed = { "c", "lua", "luadoc", "go", "javascript", "typescript", "json", "json5", "jsdoc", "yaml", "xml", "vim", "vimdoc", "tsx", "scheme", "make", "dot", "dockerfile", "csv", "diff", "gitignore", "gitcommit", "git_config", "git_rebase", "gitattributes", "css", "comment", "gomod", "gosum", "gowork", "html", "ini", "markdown", "markdown_inline", "passwd", "proto", "scss", "sql", "regex", "bash", "helm" },

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
        local ok, stats = pcall((vim.uv or vim.loop).fs_stat, vim.api.nvim_buf_get_name(buf))
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
