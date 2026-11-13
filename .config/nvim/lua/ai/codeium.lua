local M = {
  'Exafunction/codeium.vim',
  event = 'InsertEnter'
}

function M.config()
  vim.keymap.set('i', '<M-\\>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
  vim.keymap.set('i', '<M-/>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })

  -- lazy.nvim loads this plugin during the first InsertEnter event. Its own
  -- BufEnter hook has already passed for the current buffer, so start the
  -- language server explicitly now instead of eagerly on every buffer visit.
  vim.fn['codeium#command#StartLanguageServer']()
end

return M
