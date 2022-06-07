require('bufferline').setup {
  options = {
    close_command = "bdelete! %d",
    right_mouse_command = nil, -- can be a string | function, see "Mouse actions"
    middle_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
    separator_style = "slant",
    diagnostics = "coc",
    diagnostics_update_in_insert = true,
    tab_size = 18,
    enforce_regular_tabs = false,
    color_icons = true,
    offsets = {{filetype = "NvimTree", text = "File Explorer" }},
  }
}
