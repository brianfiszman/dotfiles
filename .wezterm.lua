local wezterm = require 'wezterm'

local function enable_wayland()
	local wayland = os.getenv("XDG_SESSION_TYPE")
	if wayland == "wayland" then
		return true
	end
	return false
end

-- Makes FontAwesome's double-width glyphs display properly!
return {
  font = wezterm.font('FiraCode Nerd Font', {}),
  font_size = 13.0,
  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
  font_antialias = "Subpixel",
  freetype_load_target = "HorizontalLcd",
  freetype_render_target = 'HorizontalLcd',
  harfbuzz_features = {"zero" , "ss01", "cv05"},
  window_background_opacity     = 0.75,
  color_scheme_dirs = { '.config/wezterm/colors' },
  enable_tab_bar = false,
  enable_wayland = enable_wayland(),
  check_for_updates = false,
  -- disable_default_key_bindings = true,
  keys = {
    { key = 'F11', action = wezterm.action.ToggleFullScreen },
    { key = 'UpArrow', mods = "CTRL|SHIFT", action = 'DisableDefaultAssignment' },
    { key = 'DownArrow', mods = "CTRL|SHIFT", action = 'DisableDefaultAssignment' },
    { key = 'LeftArrow', mods = "CTRL|SHIFT", action = 'DisableDefaultAssignment' },
    { key = 'RightArrow', mods = "CTRL|SHIFT", action = 'DisableDefaultAssignment' },
    -- { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.Copy },
    -- { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.Paste },
    -- { key = '-', mods = 'CTRL|SHIFT', action = wezterm.action.DecreaseFontSize },
    -- { key = '+', mods = 'CTRL|SHIFT', action = wezterm.action.IncreaseFontSize },
    -- { key = '0', mods = 'CTRL|SHIFT', action = wezterm.action.ResetFontSize },
  },
  set_environment_variables = {
    TERMINFO_DIRS = '/home/user/.nix-profile/share/terminfo',
    WSLENV = 'TERMINFO_DIRS',
  },
  color_scheme = "Builtin Tango Dark",
}
