local ls = require('luasnip')

-- Keep jump points alive while the cursor is idle. Let LuaSnip leave the
-- active region only when normal/insert-mode cursor movement actually exits it.
ls.setup({
  region_check_events = { "CursorMoved", "CursorMovedI" },
})

vim.keymap.set({ "i" }, "<Tab>", function() ls.expand() end, { silent = true })
vim.keymap.set({ "i", "s" }, "<Tab>", function() ls.jump(1) end, { silent = true })
vim.keymap.set({ "i", "s" }, "<S-Tab>", function() ls.jump(-1) end, { silent = true })

vim.keymap.set({ "i", "s" }, "<C-E>", function()
  if ls.choice_active() then
    ls.change_choice(1)
  end
end, { silent = true })
