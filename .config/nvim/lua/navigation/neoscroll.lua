return {
  "karb94/neoscroll.nvim",
  config = function()
    local neoscroll = require("neoscroll")

    -- One animation owner for page, line, and alignment motions.
    -- Keep the native mouse wheel immediate; repeated wheel events should not
    -- queue an animation behind the user's hand.
    neoscroll.setup({
      mappings = {
        "<C-u>", "<C-d>", "<C-b>", "<C-f>",
        "<C-y>", "<C-e>",
        "zt", "zz", "zb",
      },
      easing = "sine",
    })

    local modes = { "n", "v", "x" }
    vim.keymap.set(modes, "<S-Up>", function()
      neoscroll.ctrl_u({ duration = 250, easing = "sine" })
    end, {
      desc = "Smooth half-page scroll up",
      silent = true,
    })
    vim.keymap.set(modes, "<S-Down>", function()
      neoscroll.ctrl_d({ duration = 250, easing = "sine" })
    end, {
      desc = "Smooth half-page scroll down",
      silent = true,
    })
  end,
}
