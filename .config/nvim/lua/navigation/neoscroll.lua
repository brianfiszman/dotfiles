return {
  "karb94/neoscroll.nvim",
  config = function()
    local neoscroll = require("neoscroll")

    -- One animation owner for page, line, and alignment motions.
    -- Keep the native mouse wheel immediate; repeated wheel events should not
    -- queue an animation behind the user's hand.
    neoscroll.setup({
      mappings = {
        "<C-u>", "<C-d>", "<C-b>",
        "zt", "zz", "zb",
      },
      easing = "sine",
    })

    local modes = { "n", "v", "x" }
    -- Conform owns <C-f> for formatting; use the named page keys for the
    -- equivalent animated viewport motions instead of stealing that mapping.
    vim.keymap.set(modes, "<PageDown>", function()
      neoscroll.ctrl_f({ duration = 450, easing = "sine" })
    end, {
      desc = "Smooth page down",
      silent = true,
    })
    vim.keymap.set(modes, "<PageUp>", function()
      neoscroll.ctrl_b({ duration = 450, easing = "sine" })
    end, {
      desc = "Smooth page up",
      silent = true,
    })
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
