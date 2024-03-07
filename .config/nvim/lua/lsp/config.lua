-- lsp-config.lua

-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
return function(lsp_zero, servers)
  local lspconfig = require("lspconfig")
  local cmp_nvim_lsp = require("cmp_nvim_lsp")
  local capabilities = cmp_nvim_lsp.default_capabilities()
  local keymap = vim.keymap -- for conciseness
  local opts = { noremap = true, silent = true }

  require("mason").setup({
    ui = {
      border = "rounded",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })
  require("mason-lspconfig").setup {
    ensure_installed = servers,
    handlers = { lsp_zero.default_setup }
  }


  -- import lspconfig plugin

  require("neodev").setup({
    library = {
      enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
      -- these settings will be used for your Neovim config directory
      runtime = true, -- runtime path
      plugins = { "neotest", "nvim-dap-ui", "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
      types = true
    },
    setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
    lspconfig = true,
    pathStrict = true,
  })
  require('luasnip.loaders.from_vscode').lazy_load()
  require("typescript-tools").setup {
    complete_function_calls = true,
    disable_member_code_lens = false,
    code_lens = true,
  }

  cmp_nvim_lsp.setup()

  local on_attach = function(client, bufnr)
    opts.buffer = bufnr

    -- set keybinds
    opts.desc = "Show LSP references"
    keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

    opts.desc = "Go to declaration"
    keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

    opts.desc = "Show LSP definitions"
    keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

    opts.desc = "Show LSP implementations"
    keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

    opts.desc = "Show LSP type definitions"
    keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

    opts.desc = "See available code actions"
    keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

    opts.desc = "Smart rename"
    keymap.set("n", "<F2>", vim.lsp.buf.rename, opts) -- smart rename

    opts.desc = "Show buffer diagnostics"
    keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

    opts.desc = "Show line diagnostics"
    keymap.set("n", "<leader>DF", vim.diagnostic.open_float, opts) -- show diagnostics for line

    opts.desc = "Go to previous diagnostic"
    keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

    opts.desc = "Go to next diagnostic"
    keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

    opts.desc = "Show documentation for what is under cursor"
    keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

    opts.desc = "Restart LSP"
    keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

    -- require "lsp_signature".on_attach({
    --   bind = true,
    --   handler_opts = {
    --     border = "rounded",
    --   },
    -- }, bufnr)
  end

  -- Change the Diagnostic symbols in the sign column (gutter)
  -- (not in youtube nvim video)
  local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
  end

  for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup {
      on_attach = on_attach,
      capabilities = capabilities,
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "if_many",
        prefix = "●",
      },
      severity_sort = true,
    }
  end

  lspconfig.tsserver.setup {
    capabilities = capabilities,
    on_attach = on_attach,
    single_file_support = false,
    root_dir = lspconfig.util.root_pattern("yarn.lock", "package-lock.json"),
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    settings = {
      completions = {
        completeFunctionCalls = true,
        showTodos = true,
      }
    }
  }

  lspconfig.eslint.setup({
    on_attach = function(_, bufnr)
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        command = "EslintFixAll",
      })
    end,
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    capabilities = capabilities,
    settings = {
      -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
      workingDirectories = { mode = "auto" },
    },
    single_file_support = false,
  })

  -- configure svelte server
  lspconfig["svelte"].setup({
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    capabilities = capabilities,
    on_attach = function(client, bufnr)
      on_attach(client, bufnr)

      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.js", "*.ts" },
        callback = function(ctx)
          if client.name == "svelte" then
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
          end
        end,
      })
    end,
  })


  lspconfig.docker_compose_language_service.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    root_dir = lspconfig.util.root_pattern(
      "docker-compose.yml",
      "docker-compose.yaml"
    ),
    filetypes = { "yaml.docker-compose" },
    single_file_support = false,
  })

  lspconfig.gopls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    settings = {
      gopls = {
        gofumpt = true,
      },
    },
  })

  lspconfig.yamlls.setup({
    on_attach = on_attach,
    capabilities = capabilities,
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    settings = {
      yaml = {
        validate = false,
        schemas = {
          ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
        },
      },
    },
    filetypes = { "yaml" },
  })

  -- configure lua server (with special settings)
  lspconfig.lua_ls.setup({
    capabilities = capabilities,
    settings = { -- custom settings for lua
      Lua = {
        completion = {
          callSnippet = "Replace"
        },
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
        -- make the language server recognize "vim" global
        diagnostics = {
          underline = true,
          update_in_insert = false,
          globals = { "vim" },
        },
        workspace = {
          -- make language server aware of runtime files
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,
          },
        },
      },
    },
  })
end
