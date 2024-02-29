local M = {
  'stevearc/conform.nvim',
  opts = {},
}

function M.config()
  local wk = require "which-key"

  vim.api.nvim_create_user_command("Format", function(args)
    local range = nil
    if args.count ~= -1 then
      local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
      range = {
        start = { args.line1, 0 },
        ["end"] = { args.line2, end_line:len() },
      }
    end
    require("conform").format({ async = true, lsp_fallback = true, range = range })
  end, { range = true })


  wk.register {
    ["<C-f>"] = { "<cmd>Format<cr>", "Format" },
  }

  require('conform').setup({
    formatters_by_ft = {
      lua = { "stylua" },
      -- Conform will run multiple formatters sequentially
      python = { "isort", "black" },
      -- Use a sub-list to run only the first available formatter
      javascript = { { "prettierd", "prettier" } },
      typescript = { { "prettierd", "prettier" } },

      javascriptreact = { { "prettierd", "prettier" } },
      typescriptreact = { { "prettierd", "prettier" } },
      -- Conform will run multiple formatters sequentially
      go = { "goimports", "gofmt" },
      -- Use the "*" filetype to run formatters on all filetypes.
      ["*"] = { "codespell" },
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      ["_"] = { "trim_whitespace" },
      dockerfile = { "hadolint" },
      dockercompose = { "hadolint" },
      yaml = { "yamlfmt" },
      json = { "jq" },
      markdown = { "markdownlint" },
      html = { "tidy" },
      xml = { "tidy" },
      css = { "tidy" },
      sql = { "sqlfluff" },
      helm = { "helmfmt" },
      sh = { "shfmt" },
      jsonc = { "jsonlint" },
    },
    -- Conform will notify you when a formatter errors
    notify_on_error = true,
  })
end

return M
