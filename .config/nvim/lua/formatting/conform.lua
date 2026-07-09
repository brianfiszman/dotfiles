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

  -- Picks the first available formatter without stop_after_first, which
  -- would also swallow the "*" codespell pass that runs after it.
  local function first(bufnr, ...)
    local conform = require("conform")
    for i = 1, select("#", ...) do
      local formatter = select(i, ...)
      if conform.get_formatter_info(formatter, bufnr).available then
        return formatter
      end
    end
    return select(1, ...)
  end

  require('conform').setup({
    formatters_by_ft = {
      lua = { "stylua" },
      -- Conform will run multiple formatters sequentially
      python = { "isort", "black" },
      -- Run only the first available formatter
      javascript = function(bufnr) return { first(bufnr, "prettierd", "prettier") } end,
      typescript = function(bufnr) return { first(bufnr, "prettierd", "prettier") } end,

      javascriptreact = function(bufnr) return { first(bufnr, "prettierd", "prettier") } end,
      typescriptreact = function(bufnr) return { first(bufnr, "prettierd", "prettier") } end,
      -- Conform will run multiple formatters sequentially
      go = { "goimports", "gofmt" },
      -- Use the "*" filetype to run formatters on all filetypes.
      ["*"] = { "codespell" },
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      ["_"] = { "trim_whitespace" },
      -- hadolint is a linter with no format mode; Dockerfile checking
      -- happens through nvim-lint instead.
      yaml = { "yamlfmt" },
      json = { "jq" },
      markdown = { "markdownlint" },
      html = { "tidy" },
      xml = { "tidy" },
      css = { "tidy" },
      sql = { "sqlfluff" },
      -- no helm-template formatter exists (helm template renders, yamlfmt
      -- chokes on Go-template directives), so just trim whitespace
      helm = { "trim_whitespace" },
      sh = { "shfmt" },
      jsonc = { "jsonlint" },
    },
    formatters = {
      -- the builtin requires a .sqlfluff/pyproject root because sqlfluff
      -- needs a dialect; none of the workspace repos have one, so pass the
      -- same ansi default nvim-lint's sqlfluff uses
      sqlfluff = { require_cwd = false, args = { "fix", "--dialect", "ansi", "-" } },
      -- not conform builtins, so they need explicit definitions
      jsonlint = { command = "jsonlint", stdin = true },
      tidy = {
        command = "tidy",
        args = { "-quiet", "--tidy-mark", "no" },
        stdin = true,
        -- tidy exits 1 on warnings while still emitting formatted output
        exit_codes = { 0, 1 },
      },
    },
    -- Conform will notify you when a formatter errors
    notify_on_error = true,
  })
end

return M
