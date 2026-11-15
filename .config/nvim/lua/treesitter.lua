local legacy_treesitter_commit = "85168f15808d89b0222313652b9d2777eda3cb08"
local legacy_compat_patch = "patches/nvim-treesitter-neovim-0.12.patch"
local query_predicates_module = "nvim-treesitter.query_predicates"
local query_predicates_file = "lua/nvim-treesitter/query_predicates.lua"

local function git(plugin, args)
  local command = { "git", "-C", plugin.dir }
  vim.list_extend(command, args)
  return vim.system(command, { text = true }):wait()
end

local function install_legacy_query_predicates_adapter(plugin)
  if vim.fn.isdirectory(plugin.dir) ~= 1 then
    return
  end

  local revision = git(plugin, { "rev-parse", "HEAD" })
  if revision.code ~= 0 then
    error("Could not inspect the nvim-treesitter checkout: " .. (revision.stderr or "unknown Git error"))
  end

  local head = (revision.stdout or ""):gsub("%s+$", "")
  -- Scope this compatibility layer to the exact legacy revision. A newer
  -- upstream revision must be validated independently, not patched blindly.
  if head ~= legacy_treesitter_commit then
    return
  end

  local source_file = plugin.dir .. "/" .. query_predicates_file
  if vim.fn.filereadable(source_file) ~= 1 then
    error("The locked nvim-treesitter query-predicate module is missing: " .. source_file)
  end

  -- Migrate installations that received the previous on-disk patch. Reverse
  -- only that exact patch; if the file has unrelated local edits, leave them
  -- untouched and fail with an actionable message.
  local patch = vim.fn.stdpath("config") .. "/" .. legacy_compat_patch
  local reverse_check = git(plugin, { "apply", "--reverse", "--check", patch })
  if reverse_check.code == 0 then
    local reverse = git(plugin, { "apply", "--reverse", patch })
    if reverse.code ~= 0 then
      error("Could not restore the upstream nvim-treesitter query-predicate file: "
        .. (reverse.stderr or "unknown Git error"))
    end
  else
    local forward_check = git(plugin, { "apply", "--check", patch })
    if forward_check.code ~= 0 then
      error("The nvim-treesitter query-predicate file differs from both the upstream and "
        .. "previous dotfiles-patched versions. No further local edits were made. "
        .. (reverse_check.stderr or reverse_check.stdout or ""))
    end
  end

  local clean = git(plugin, { "diff", "--quiet", "--", query_predicates_file })
  if clean.code ~= 0 then
    error("The nvim-treesitter query-predicate file still has local changes after migration; "
      .. "refusing to install the compatibility adapter.")
  end

  -- Neovim 0.12 returns a list of nodes for each query capture. The locked
  -- legacy plugin expects a single TSNode. Adapt only the handlers registered
  -- while its query_predicates module loads; do not change the global query API
  -- or modify any file inside the plugin checkout.
  if package.loaded[query_predicates_module] or package.preload[query_predicates_module] then
    return
  end

  package.preload[query_predicates_module] = function()
    local query = vim.treesitter.query
    local add_predicate = query.add_predicate
    local add_directive = query.add_directive

    local function adapt_handler(handler)
      return function(match, ...)
        local single_node_captures = {}
        for capture_id, captured in pairs(match) do
          if type(captured) == "table" then
            single_node_captures[capture_id] = captured[#captured]
          else
            single_node_captures[capture_id] = captured
          end
        end
        return handler(single_node_captures, ...)
      end
    end

    query.add_predicate = function(name, handler, opts)
      return add_predicate(name, adapt_handler(handler), opts)
    end
    query.add_directive = function(name, handler, opts)
      return add_directive(name, adapt_handler(handler), opts)
    end

    local chunk, load_error = loadfile(source_file)
    if not chunk then
      query.add_predicate = add_predicate
      query.add_directive = add_directive
      error("Could not load the locked nvim-treesitter query-predicate module: " .. tostring(load_error))
    end

    local ok, result = xpcall(chunk, debug.traceback)
    query.add_predicate = add_predicate
    query.add_directive = add_directive
    if not ok then
      error("Could not register the nvim-treesitter compatibility predicates: " .. tostring(result))
    end
    return true
  end
end

local M = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    -- Additional text objects for treesitter
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  -- init migrates the old disk patch and installs the in-memory adapter for
  -- existing checkouts before plugin modules load. build handles fresh clones
  -- created during the first startup. Neither path modifies plugin source.
  init = vim.fn.has("nvim-0.12") == 1 and install_legacy_query_predicates_adapter or nil,
  -- Keep the original parser update path on Neovim 0.11.3.
  build = vim.fn.has("nvim-0.12") == 1 and install_legacy_query_predicates_adapter or ":TSUpdate",
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
