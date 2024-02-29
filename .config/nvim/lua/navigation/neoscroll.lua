return {
  "karb94/neoscroll.nvim",
  config = function ()
    require('neoscroll').setup {
      mappings = {'<S-up>', '<S-down>'},
    }
  end
}
