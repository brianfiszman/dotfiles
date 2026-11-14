local M = {}

M.servers = {
  "lua_ls",
  "arduino_language_server",
  "bashls",
  "clangd",
  "cssls",
  "diagnosticls",
  "docker_compose_language_service",
  "eslint",
  "dotls",
  "graphql",
  "html",
  "helm_ls",
  "jsonls",
  "marksman",
  "spectral",
  "dockerls",
  "tailwindcss",
  "yamlls",
  "gopls",
  "svelte",
  "ts_ls",
}

local function set_lsp_keymap(mode, lhs, rhs, description, bufnr)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    desc = description,
    noremap = true,
    silent = true,
  })
end

local function on_attach(client, bufnr)
  set_lsp_keymap("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references", bufnr)
  set_lsp_keymap("n", "gD", vim.lsp.buf.declaration, "Go to declaration", bufnr)
  set_lsp_keymap("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Show LSP definitions", bufnr)
  set_lsp_keymap("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations", bufnr)
  set_lsp_keymap("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions", bufnr)
  set_lsp_keymap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "See available code actions", bufnr)
  set_lsp_keymap("n", "<F2>", vim.lsp.buf.rename, "Smart rename", bufnr)
  set_lsp_keymap("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Show buffer diagnostics", bufnr)
  set_lsp_keymap("n", "<leader>DF", vim.diagnostic.open_float, "Show line diagnostics", bufnr)
  set_lsp_keymap("n", "[d", function()
    vim.diagnostic.jump({
      count = -1,
      on_jump = function(_, target_bufnr)
        vim.diagnostic.open_float({ bufnr = target_bufnr, scope = "cursor", focus = false })
      end,
    })
  end, "Go to previous diagnostic", bufnr)
  set_lsp_keymap("n", "]d", function()
    vim.diagnostic.jump({
      count = 1,
      on_jump = function(_, target_bufnr)
        vim.diagnostic.open_float({ bufnr = target_bufnr, scope = "cursor", focus = false })
      end,
    })
  end, "Go to next diagnostic", bufnr)
  set_lsp_keymap("n", "K", vim.lsp.buf.hover, "Show documentation", bufnr)
  set_lsp_keymap("n", "<leader>rs", "<cmd>LspRestart<CR>", "Restart LSP", bufnr)

  -- Preserve lsp-zero's default mappings that are not replaced above.
  set_lsp_keymap("n", "go", vim.lsp.buf.type_definition, "Go to type definition", bufnr)
  set_lsp_keymap("n", "gr", vim.lsp.buf.references, "Go to references", bufnr)
  set_lsp_keymap("n", "<F3>", function()
    vim.lsp.buf.format({ async = true })
  end, "Format buffer", bufnr)
  set_lsp_keymap("x", "<F3>", function()
    vim.lsp.buf.format({ async = true })
  end, "Format selection", bufnr)
  set_lsp_keymap("n", "<F4>", vim.lsp.buf.code_action, "Execute code action", bufnr)

  set_lsp_keymap({ "n", "x" }, "<C-S-f>", function()
    vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
  end, "Format synchronously", bufnr)
end

local function eslint_on_attach(client, bufnr)
  on_attach(client, bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    callback = function()
      vim.cmd("EslintFixAll")
    end,
    desc = "Apply ESLint fixes before saving",
  })
end

local svelte_autocmds = {}

local function svelte_on_attach(client, bufnr)
  on_attach(client, bufnr)

  -- A Svelte client can attach to multiple buffers; register one project-wide
  -- watcher per client rather than duplicating a global autocmd per buffer.
  if svelte_autocmds[client.id] then
    return
  end

  svelte_autocmds[client.id] = vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { "*.js", "*.ts" },
    callback = function(ctx)
      client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.file) })
    end,
    desc = "Notify Svelte LSP about JavaScript and TypeScript changes",
  })
end

local function configure_server(name, overrides)
  local config = vim.tbl_deep_extend("force", {
    capabilities = M.capabilities,
    on_attach = on_attach,
  }, overrides or {})
  vim.lsp.config(name, config)
end

function M.setup()
  local cmp_nvim_lsp = require("cmp_nvim_lsp")
  M.capabilities = cmp_nvim_lsp.default_capabilities()
  cmp_nvim_lsp.setup()

  -- Mason installs tools only. Explicit vim.lsp.enable() calls below own activation.
  M.mason_options = {
    ensure_installed = M.servers,
    automatic_enable = false,
  }
  require("mason-lspconfig").setup(M.mason_options)

  -- Keep Neodev for now; its migration to lazydev is tracked independently in #42.
  -- Integrate through before_init instead of its deprecated lspconfig hook.
  require("neodev").setup({
    library = {
      enabled = true,
      runtime = true,
      plugins = { "neotest", "nvim-dap-ui", "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
      types = true,
    },
    setup_jsonls = false,
    lspconfig = false,
    pathStrict = true,
  })

  require("luasnip.loaders.from_vscode").lazy_load()
  require("snippets.nvim_cmp")()

  vim.diagnostic.config({
    underline = true,
    update_in_insert = false,
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✘",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.HINT] = "⚑",
        [vim.diagnostic.severity.INFO] = "»",
      },
    },
    float = {
      border = "rounded",
      source = "always",
    },
  })

  local server_overrides = {
    eslint = {
      on_attach = eslint_on_attach,
      settings = {
        workingDirectories = { mode = "auto" },
      },
      workspace_required = true,
    },
    svelte = {
      on_attach = svelte_on_attach,
    },
    docker_compose_language_service = {
      filetypes = { "yaml.docker-compose" },
      root_dir = function(bufnr, on_dir)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(filename, { "docker-compose.yml", "docker-compose.yaml" })
        if root then
          on_dir(root)
        end
      end,
      workspace_required = true,
    },
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
        },
      },
    },
    yamlls = {
      filetypes = { "yaml" },
      settings = {
        yaml = {
          validate = false,
          schemas = {
            ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
          },
        },
      },
    },
    lua_ls = {
      before_init = require("neodev.lsp").before_init,
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.stdpath("config") .. "/lua"] = true,
            },
          },
        },
      },
    },
    ts_ls = {
      root_markers = { "yarn.lock", "package-lock.json" },
      workspace_required = true,
      settings = {
        typescript = {
          completions = {
            completeFunctionCalls = true,
          },
          implementationsCodeLens = {
            enabled = true,
            showOnAllClassMethods = true,
            showOnInterfaceMethods = true,
          },
          referencesCodeLens = {
            enabled = true,
            showOnAllFunctions = true,
          },
        },
        javascript = {
          completions = {
            completeFunctionCalls = true,
          },
          referencesCodeLens = {
            enabled = true,
            showOnAllFunctions = true,
          },
        },
      },
    },
  }

  for _, server in ipairs(M.servers) do
    configure_server(server, server_overrides[server])
  end
  -- All configured servers, including TypeScript, have one explicit activation path.
  vim.lsp.enable(M.servers)
  M.enabled_servers = vim.deepcopy(M.servers)
end

return M
