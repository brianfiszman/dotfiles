-- Set up nvim-cmp.
return function(lsp_zero)
  local cmp = require 'cmp'
  local cmp_action = lsp_zero.cmp_action()
  local lspkind = require('lspkind')
  local saga = require('lspsaga')

  saga.setup({ symbol_in_winbar = { enable = false } })

  cmp.setup({
    sources = cmp.config.sources({
      { name = 'codeium' },
      { name = 'luasnip',                keyword_length = 3, option = { show_autosnippets = true } }, -- For luasnip users.
      { name = 'nvim_lsp' },
      { name = 'nvim_lsp_signature_help' },
      { name = 'nvim_lua' },
      { name = 'dotenv' },
      { name = 'buffer',                 keyword_length = 4 },
      { name = 'path',                   keyword_length = 3 },
      { name = 'treesitter' }
    }),
    sorting = {
      comparators = {
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.score,
        require("cmp-under-comparator").under,
        cmp.config.compare.recently_used,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args) require('luasnip').lsp_expand(args.body) end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    formatting = {
      fields = { "kind", "abbr", 'menu' },
      format = lspkind.cmp_format({
        mode = 'symbol', -- show only symbol annotations
        maxwidth = 50,   -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
        -- can also be a function to dynamically calculate max width such as
        -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
        ellipsis_char = '...',    -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
        show_labelDetails = true, -- show labelDetails in menu. Disabled by default
        symbol_map = { Codeium = "", }

        -- The function below will be called before any actual modifications from lspkind
        -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      })
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<Tab>'] = cmp_action.luasnip_jump_forward(),
      ['<S-Tab>'] = cmp_action.luasnip_jump_backward(),
      ['<Tab>'] = cmp_action.luasnip_supertab(),
      ['<S-Tab>'] = cmp_action.luasnip_shift_supertab(),
    }),
  })

  -- Set configuration for specific filetype.
  cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
    }, {
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

  local sign = function(opts)
    vim.fn.sign_define(opts.name, {
      texthl = opts.name,
      text = opts.text,
      numhl = ''
    })
  end

  sign({ name = 'DiagnosticSignError', text = '✘' })
  sign({ name = 'DiagnosticSignWarn', text = '▲' })
  sign({ name = 'DiagnosticSignHint', text = '⚑' })
  sign({ name = 'DiagnosticSignInfo', text = '»' })

  vim.diagnostic.config({
    virtual_text = false,
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'always',
    },
  })

  vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
    vim.lsp.handlers.hover,
    { border = 'rounded' }
  )

  vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
    vim.lsp.handlers.signature_help,
    { border = 'rounded' }
  )

  require('lspconfig.ui.windows').default_options.border = 'rounded'
end
