local parser_languages = {
  "c",
  "lua",
  "luadoc",
  "go",
  "javascript",
  "typescript",
  "json",
  "json5",
  "jsdoc",
  "yaml",
  "xml",
  "vim",
  "vimdoc",
  "tsx",
  "scheme",
  "make",
  "dot",
  "dockerfile",
  "csv",
  "diff",
  "gitignore",
  "gitcommit",
  "git_config",
  "git_rebase",
  "gitattributes",
  "css",
  "comment",
  "gomod",
  "gosum",
  "gowork",
  "html",
  "ini",
  "markdown",
  "markdown_inline",
  "passwd",
  "proto",
  "scss",
  "sql",
  "regex",
  "bash",
  "helm",
}

local indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
local install_timeout_ms = 20 * 60 * 1000
local updating_parsers = false
local pending_parser_update = false

local function has_query(language, query_name)
  local ok, query = pcall(vim.treesitter.query.get, language, query_name)
  return ok and query ~= nil
end

local function configure_buffer(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  local language = vim.treesitter.language.get_lang(filetype)
  if not language then
    return
  end

  -- Preserve the legacy modules' capability checks. Parsers installed outside
  -- the managed 41-language set must remain usable when their queries exist.
  local has_indents = has_query(language, "indents")
  local has_highlights = has_query(language, "highlights")
  if not has_indents and not has_highlights then
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, language)
  if not ok or not parser then
    return
  end

  if has_indents then
    vim.bo[bufnr].indentexpr = indentexpr
  end

  -- Preserve the previous 100 KiB Treesitter highlighting limit without
  -- disabling parser-backed indentation for larger files.
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local stat = filename ~= "" and (vim.uv or vim.loop).fs_stat(filename) or nil
  if stat and stat.size > 100 * 1024 then
    return
  end

  if has_highlights then
    local started, err = pcall(vim.treesitter.start, bufnr, language)
    if not started then
      vim.notify(
        ("Could not enable Treesitter highlighting for %s: %s"):format(filetype, tostring(err)),
        vim.log.levels.ERROR,
        { title = "dotfiles Treesitter" }
      )
    else
      -- The legacy configuration enabled additional Vim regex highlighting
      -- alongside Treesitter. The FileType syntax hook skips buffers marked
      -- b:ts_highlight, so explicitly retain that second highlighting layer.
      vim.bo[bufnr].syntax = "ON"
    end
  end
end

local function setup_parsers(update_existing)
  if updating_parsers then
    return
  end
  updating_parsers = true

  local ok, err = xpcall(function()
    local executable = vim.fn.exepath("tree-sitter")
    assert(executable ~= "", "tree-sitter-cli is missing from Neovim's PATH")

    local version_result = vim.system({ executable, "--version" }, { text = true }):wait()
    assert(version_result.code == 0,
      "tree-sitter --version failed: " .. (version_result.stderr or "unknown error"))
    local version = vim.trim(version_result.stdout or "")
    assert(version == "tree-sitter 0.27.2",
      "tree-sitter-cli 0.27.2 is required; found " .. version)

    local treesitter = require("nvim-treesitter")
    local installed = {}
    for _, language in ipairs(treesitter.get_installed("parsers")) do
      installed[language] = true
    end

    local missing = vim.tbl_filter(function(language)
      return not installed[language]
    end, parser_languages)

    if #missing > 0 then
      local installed_ok = treesitter.install(missing, { summary = true }):wait(install_timeout_ms)
      assert(installed_ok ~= false, "nvim-treesitter failed to install missing parsers")
      print(("[treesitter] Installed %d missing parsers"):format(#missing))
    else
      print("[treesitter] All configured parsers are already installed; skipping compilation")
    end

    if update_existing then
      local updated_ok = treesitter.update(parser_languages, { summary = true }):wait(install_timeout_ms)
      assert(updated_ok ~= false, "nvim-treesitter failed to update parsers")
      print(("[treesitter] Updated %d parsers after the plugin revision changed"):format(#parser_languages))
    end

    vim.g.dotfiles_treesitter_ready = true
    vim.g.dotfiles_treesitter_error = nil
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      configure_buffer(bufnr)
    end

    print(("[treesitter] CLI %s; %d parsers requested; provisioning complete")
      :format(version, #parser_languages))
  end, debug.traceback)

  updating_parsers = false
  if not ok then
    vim.g.dotfiles_treesitter_ready = false
    vim.g.dotfiles_treesitter_error = tostring(err)
    vim.notify(
      "Treesitter parser setup failed. See :messages.\n" .. tostring(err),
      vim.log.levels.ERROR,
      { title = "dotfiles Treesitter" }
    )
    return false
  end
  return true
end

local function provision_missing_parsers()
  -- Mason's first install is asynchronous. Do not record an error while its
  -- CLI is still being installed; the real completion event retries setup.
  if vim.fn.executable("tree-sitter") ~= 1 then
    print("[treesitter] tree-sitter-cli is not ready yet; waiting for Mason completion")
    return
  end

  -- A plugin revision may have changed while the CLI was unavailable during
  -- lazy.nvim restore. Preserve that explicit update request until Mason is
  -- ready; otherwise this path only fills parser gaps.
  local update_existing = pending_parser_update
  local ok = setup_parsers(update_existing)
  if ok then
    pending_parser_update = false
  end
end

local function update_existing_parsers(plugin)
  -- lazy.nvim's :Lazy! build force-runs every configured build hook when a
  -- plugin cache is restored. Only refresh parsers when nvim-treesitter itself
  -- moved to a different locked revision; an unchanged cached plugin must not
  -- invalidate the compiled parser cache.
  local metadata = plugin and plugin._ or {}
  local updated = metadata.updated
  if updated and updated.from == updated.to then
    print("[treesitter] nvim-treesitter revision unchanged; preserving compiled parsers")
    return
  end

  -- A freshly cloned plugin has no previous parser-query revision to migrate.
  -- An existing checkout with missing update metadata still uses the explicit
  -- build hook as its update signal.
  local update_requested = updated and updated.from ~= updated.to or not metadata.cloned
  if vim.fn.executable("tree-sitter") ~= 1 then
    pending_parser_update = update_requested
    print("[treesitter] tree-sitter-cli is not installed yet; parser setup will run after Mason installs it")
    return
  end

  local ok = setup_parsers(update_requested)
  assert(ok and vim.g.dotfiles_treesitter_ready,
    "Treesitter parser update failed: " .. tostring(vim.g.dotfiles_treesitter_error))
end

local M = {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  dependencies = {
    "mason-org/mason.nvim",
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      config = function(_, opts)
        local installer = require("mason-tool-installer")
        installer.setup(vim.tbl_deep_extend("force", opts, {
          -- The plugin's VimEnter hook can fire before Lazy applies this
          -- config when the dependency itself is loaded during VimEnter.
          -- Start explicitly after setup so ensure_installed is populated and
          -- the parent Treesitter completion listener is already registered.
          run_on_start = false,
        }))
        -- CI's plugin-restore phase only restores revisions/build hooks.
        -- Defer Mason CLI provisioning and parser compilation to the following
        -- normal-startup process, where their completion is awaited explicitly.
        if vim.env.DOTFILES_SKIP_TREESITTER_PROVISIONING ~= "1" then
          vim.schedule(function()
            installer.check_install(false)
            -- Mason emits no completion event when every requested package
            -- is already installed. Probe after the check too; if installation
            -- is still running, its completion event provisions the parsers.
            vim.schedule(provision_missing_parsers)
          end)
        else
          print("[treesitter] CLI/parser provisioning deferred until normal startup")
        end
      end,
      opts = {
        ensure_installed = { { "tree-sitter-cli", version = "v0.27.2" } },
        auto_update = false,
        run_on_start = false,
        start_delay = 0,
        -- The installer otherwise requires mason-nvim-dap.mappings.source.
        -- Lazy treats that module require as a plugin trigger, which eagerly
        -- loads the DAP stack during every normal startup.
        integrations = {
          ["mason-nvim-dap"] = false,
        },
      },
    },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
      config = function()
        require("nvim-treesitter-textobjects").setup({
          select = { lookahead = true },
          move = { set_jumps = true },
        })

        local select = require("nvim-treesitter-textobjects.select")
        local move = require("nvim-treesitter-textobjects.move")
        local group = vim.api.nvim_create_augroup("DotfilesGoTextobjects", { clear = true })

        vim.api.nvim_create_autocmd("FileType", {
          group = group,
          pattern = "go",
          callback = function(args)
            local function map(modes, lhs, callback, description)
              vim.keymap.set(modes, lhs, callback, {
                buffer = args.buf,
                silent = true,
                desc = description,
              })
            end

            map({ "x", "o" }, "af", function()
              select.select_textobject("@function.outer", "textobjects")
            end, "Select Go function")

            map({ "x", "o" }, "if", function()
              select.select_textobject("@function.inner", "textobjects")
            end, "Select Go function body")

            map({ "x", "o" }, "ac", function()
              select.select_textobject("@class.outer", "textobjects")
            end, "Select Go type declaration")

            map({ "x", "o" }, "ic", function()
              select.select_textobject("@class.inner", "textobjects")
            end, "Select Go type body")

            map({ "n", "x", "o" }, "]]", function()
              move.goto_next_start("@function.outer", "textobjects")
            end, "Go to next Go function start")

            map({ "n", "x", "o" }, "][", function()
              move.goto_next_end("@function.outer", "textobjects")
            end, "Go to next Go function end")

            map({ "n", "x", "o" }, "[[", function()
              move.goto_previous_start("@function.outer", "textobjects")
            end, "Go to previous Go function start")

            map({ "n", "x", "o" }, "[]", function()
              move.goto_previous_end("@function.outer", "textobjects")
            end, "Go to previous Go function end")
          end,
          desc = "Configure current-API Treesitter textobjects for Go buffers",
        })
      end,
    },
    {
      "windwp/nvim-ts-autotag",
      config = function()
        require("nvim-ts-autotag").setup()
      end,
    },
  },
  build = update_existing_parsers,
  config = function()
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = "DotfilesTreesitter",
      callback = function(args)
        configure_buffer(args.buf)
      end,
      desc = "Enable current Neovim Treesitter highlighting and indentation",
    })

    -- mason-tool-installer installs tree-sitter-cli after VimEnter on a clean
    -- setup. Wait for its real completion event before compiling parsers.
    vim.api.nvim_create_autocmd("User", {
      group = "DotfilesTreesitter",
      pattern = "MasonToolsUpdateCompleted",
      callback = provision_missing_parsers,
      desc = "Install and update the configured Treesitter parsers",
    })

    vim.keymap.set({ "n", "x" }, "<leader>V", function()
      if vim.fn.mode():sub(1, 1) == "n" then
        vim.cmd.normal({ args = { "v" }, bang = true })
      end
      vim.treesitter.select("parent")
    end, {
      desc = "Select Treesitter parent node",
      silent = true,
    })

    vim.keymap.set("x", "<BS>", function()
      vim.treesitter.select("child")
    end, {
      desc = "Select Treesitter child node",
      silent = true,
    })
  end,
}

return M
