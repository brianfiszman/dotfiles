local M = {
  'Exafunction/codeium.vim',
  event = 'BufEnter'
}


function M.config()
  vim.keymap.set('i', '<M-\\>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
  vim.keymap.set('i', '<M-/>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
end

return M
