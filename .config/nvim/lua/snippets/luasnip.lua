local ls = require('luasnip')

vim.keymap.set({ "i" }, "<Tab>", function() ls.expand() end, { silent = true })
vim.keymap.set({ "i", "s" }, "<Tab>", function() ls.jump(1) end, { silent = true })
vim.keymap.set({ "i", "s" }, "<S-Tab>", function() ls.jump(-1) end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true })
