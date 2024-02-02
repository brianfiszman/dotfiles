-- lsp-config.lua

-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local setup_lsp_config = require 'lsp.config'
local setup_nvim_cmp = require 'snippets.nvim_cmp'
local servers = { "lua_ls", "arduino_language_server", "bashls", "clangd", "cssls", "diagnosticls",
  "docker_compose_language_service", "eslint", "dotls", "graphql", "html", "helm_ls", "jsonls", "tsserver", "marksman",
  "spectral", "dockerls", "tailwindcss", "yamlls", "gopls" }

LSP_ZERO = require 'lsp-zero'

LSP_ZERO.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  LSP_ZERO.default_keymaps({ buffer = bufnr })
  local opts = { buffer = bufnr }

  vim.keymap.set({ 'n', 'x' }, '<C-f>', function()
    vim.lsp.buf.format({ async = false, timeout_ms = 10000 })
  end, opts)
end)

LSP_ZERO.setup_servers(servers)

LSP_ZERO.configure('tsserver', {
  settings = {
    completions = {
      completeFunctionCalls = true
    }
  }
})

-- technically these are "diagnostic signs"
-- neovim enables them by default.
-- here we are just changing them to fancy icons.
LSP_ZERO.set_sign_icons({
  error = '✘',
  warn = '▲',
  hint = '⚑',
  info = '»'
})

LSP_ZERO.preset('recommended')
LSP_ZERO.setup()

setup_lsp_config(LSP_ZERO, servers)
setup_nvim_cmp(LSP_ZERO)
