local M = {
  'mfussenegger/nvim-lint',
}

function M.config()
  local lint = require('lint')

  lint.linters_by_ft = {
    fish = { 'fish' },
    lua = { 'luacheck' },
    python = { 'pylint', 'flake8' },
    rust = { 'clippy' },
    yaml = { 'yamllint' },
    markdown = { 'markdownlint', 'markdownlint-cli2' },
    json = { 'jsonlint' },
    sh = { 'shellcheck' },
    c = { 'clangtidy' },
    cpp = { 'clangtidy' },
    go = { 'golangcilint' },
    javascript = { 'eslint', 'eslint_d' },
    typescript = { 'eslint', 'eslint_d' },
    javascriptreact = { 'eslint', 'eslint_d' },
    typescriptreact = { 'eslint', 'eslint_d' },
    css = { 'stylelint' },
    scss = { 'stylelint' },
    html = { 'tidy', 'htmlhint' },
    sql = { 'sqlfluff' },
    dockerfile = { 'hadolint' },
  }

  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
    callback = function()
      -- nvim-lint raises an ERROR notification on every event when a linter
      -- binary is missing, so only run the linters whose executables resolve.
      local names = {}
      for _, name in ipairs(lint.linters_by_ft[vim.bo.filetype] or {}) do
        local linter = lint.linters[name]
        if type(linter) == 'function' then
          linter = linter()
        end
        local cmd = linter and linter.cmd
        if type(cmd) == 'function' then
          local ok, resolved = pcall(cmd)
          cmd = ok and resolved or nil
        end
        if type(cmd) == 'string' and vim.fn.executable(cmd) == 1 then
          table.insert(names, name)
        end
      end
      if #names > 0 then
        lint.try_lint(names)
      end
    end,
  })
end

return M
