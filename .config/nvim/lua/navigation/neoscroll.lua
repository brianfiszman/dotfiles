return {
  "karb94/neoscroll.nvim",
  config = function()
    local neoscroll = require('neoscroll')
    -- setup() only accepts its default keys in `mappings` now; custom keys
    -- go through the documented function API
    neoscroll.setup { mappings = {} }
    local modes = { 'n', 'v', 'x' }
    vim.keymap.set(modes, '<S-Up>', function() neoscroll.ctrl_u({ duration = 250 }) end)
    vim.keymap.set(modes, '<S-Down>', function() neoscroll.ctrl_d({ duration = 250 }) end)
  end
}
