-- Set up nvim-cmp without depending on lsp-zero.
return function()
  local cmp = require("cmp")
  local luasnip = require("luasnip")
  local lspkind = require("lspkind")
  local saga = require("lspsaga")

  local function luasnip_supertab()
    return cmp.mapping(function(fallback)
      local column = vim.fn.col(".") - 1

      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif column == 0 or vim.fn.getline("."):sub(column, column):match("%s") then
        fallback()
      else
        cmp.complete()
      end
    end, { "i", "s" })
  end

  local function luasnip_shift_supertab()
    return cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" })
  end

  vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
  saga.setup({ symbol_in_winbar = { enable = false } })

  cmp.setup({
    completion = {
      completeopt = "menu,menuone,noinsert",
    },
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "luasnip", keyword_length = 3, option = { show_autosnippets = true } },
      { name = "nvim_lsp_signature_help" },
      { name = "dotenv" },
      { name = "path", keyword_length = 3 },
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
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    formatting = {
      fields = { "kind", "abbr", "menu" },
      format = lspkind.cmp_format({
        mode = "symbol",
        maxwidth = 50,
        ellipsis_char = "...",
        show_labelDetails = true,
        symbol_map = { Codeium = "" },
      }),
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<Tab>"] = luasnip_supertab(),
      ["<S-Tab>"] = luasnip_shift_supertab(),
    }),
  })

  require("cmp_git").setup()
  cmp.setup.filetype("gitcommit", {
    sources = cmp.config.sources({
      { name = "git" },
    }, {
      { name = "buffer" },
    }),
  })

  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
    }, {
      { name = "cmdline" },
    }),
  })

  local hover = vim.lsp.buf.hover
  local signature_help = vim.lsp.buf.signature_help
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.hover = function(config)
    return hover(vim.tbl_deep_extend("force", { border = "rounded" }, config or {}))
  end
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.signature_help = function(config)
    return signature_help(vim.tbl_deep_extend("force", { border = "rounded" }, config or {}))
  end
end
