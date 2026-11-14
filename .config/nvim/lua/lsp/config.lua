local M = {}

M.mason_servers = {
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
  "ts_ls",
}

M.servers = vim.list_extend(vim.deepcopy(M.mason_servers), { "svelte" })

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

  -- Preserve lsp-zero's default navigation mappings.
  -- Formatting is owned by Conform's <C-f> / :Format path, not LSP servers.
  set_lsp_keymap("n", "go", vim.lsp.buf.type_definition, "Go to type definition", bufnr)
  set_lsp_keymap("n", "gr", vim.lsp.buf.references, "Go to references", bufnr)
  set_lsp_keymap("n", "<F4>", vim.lsp.buf.code_action, "Execute code action", bufnr)
end

local function eslint_on_attach(client, bufnr, default_on_attach)
  -- Preserve nvim-lspconfig's native on_attach, which creates the
  -- buffer-local :LspEslintFixAll command.
  if default_on_attach then
    default_on_attach(client, bufnr)
  end

  on_attach(client, bufnr)
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = bufnr,
    command = "LspEslintFixAll",
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

local function ts_ls_on_attach(client, bufnr)
  on_attach(client, bufnr)

  vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
    buffer = bufnr,
    callback = function()
      vim.lsp.codelens.refresh({ bufnr = bufnr })
    end,
    desc = "Refresh TypeScript language server CodeLens",
  })
  vim.lsp.codelens.refresh({ bufnr = bufnr })
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
    ensure_installed = M.mason_servers,
    automatic_enable = false,
  }
  require("mason-lspconfig").setup(M.mason_options)

  require("luasnip.loaders.from_vscode").lazy_load()
  require("snippets.nvim_cmp")()

  local eslint_default_on_attach = vim.lsp.config.eslint.on_attach
  assert(type(eslint_default_on_attach) == "function",
    "nvim-lspconfig native ESLint on_attach is required for LspEslintFixAll")
  M.eslint_default_on_attach = eslint_default_on_attach
  M.eslint_fix_command = "LspEslintFixAll"

  vim.diagnostic.config({
    underline = true,
    virtual_text = { spacing = 2, source = "if_many" },
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
      on_attach = function(client, bufnr)
        eslint_on_attach(client, bufnr, eslint_default_on_attach)
      end,
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
    jsonls = {
      settings = {
        json = {
          schemas = {
            {
              name = "LuaLS Settings",
              url = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
              fileMatch = { ".luarc.json", ".luarc.jsonc" },
            },
          },
          validate = {
            enable = true,
          },
        },
      },
    },
    lua_ls = {
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
            path = { "?.lua", "?/init.lua" },
          },
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
      on_attach = ts_ls_on_attach,
      root_dir = function(bufnr, on_dir)
        local root = vim.fs.root(bufnr, { "yarn.lock", "package-lock.json" })
        if root then
          on_dir(root)
        end
      end,
      workspace_required = true,
      settings = {
        typescript = {
          completions = {
            completeFunctionCalls = true,
          },
          implementationsCodeLens = {
            enabled = true,
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
          implementationsCodeLens = {
            enabled = true,
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
