require('bufferline').setup {
  options = {
    close_command = "bdelete! %d",
    right_mouse_command = nil, -- can be a string | function, see "Mouse actions"
    middle_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
    separator_style = "slant",
    diagnostics = "nvim_lsp",
    diagnostics_update_in_insert = true,
  }
}
