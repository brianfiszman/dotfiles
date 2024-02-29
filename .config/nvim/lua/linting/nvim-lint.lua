local M = {
  'mfussenegger/nvim-lint',
  -- Event to trigger linters
  events = { "BufWritePost", "BufReadPost", "InsertLeave" },
  linters_by_ft = {
    fish = { "fish", "fish_indent" },
    lua = { "luacheck", "luafmt" },
    python = { "pylint", "flake8" },
    rust = { "rustc", "cargo", "rustup" },
    yaml = { "yamllint", "yaml-language-server" },
    markdown = { "markdownlint", "markdownlint-cli2", "markdownlint-cli2-lint-fix" },
    json = { "jsonlint", "jsonlint-language-server" },
    sh = { "shellcheck" },
    c = { "clang" },
    cpp = { "clang" },
    go = { "golint", "golangci-lint", "golangci-lint-langserver" },
    javascript = { "eslint", "eslint_d", "tsserver" },
    typescript = { "eslint", "eslint_d", "tsserver" },
    typescriptreact = { "eslint", "eslint_d", "tsserver" },
    javascriptreact = { "eslint", "eslint_d", "tsserver" },
    css = { "csslint", "css-language-server" },
    html = { "tidy", "htmlhint" },
    scss = { "scsslint" },
    sql = { "sqlfluff", "sql-formatter" },
    graphql = { "gqlint" },
    dockerfile = { "hadolint", "dockerfile-language-server" },
    dockercompose = { "hadolint", "dockerfile-language-server" },
    kubeconfig = { "kubectl", "kubelint" },
    helm = { "helm", "helm-ls" },
    -- Use the "*" filetype to run linters on all filetypes.
    -- ['*'] = { 'global linter' },
    -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
    -- ['_'] = { 'fallback linter' },
  },
  -- LazyVim extension to easily override linter options
  -- or add custom linters.
  ---@type table<string,table>
  linters = {
    -- -- Example of using selene only when a selene.toml file is present
    -- selene = {
    --   -- `condition` is another LazyVim extension that allows you to
    --   -- dynamically enable/disable linters based on the context.
    --   condition = function(ctx)
    --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
    --   end,
    -- },
  },
}

return M
