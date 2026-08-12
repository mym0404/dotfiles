local opacity = 0.98
local blur = 20
local wezterm = require("wezterm")
local c = wezterm.config_builder()
local act = wezterm.action
local CMD = "CMD"
local CTRL = "CTRL"
local OPT = "OPT"
 
local function setup_core()
	c.inactive_pane_hsb = {
		saturation = 0.6,
		brightness = 0.6,
	}
	c.set_environment_variables = {
		PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
	}
	c.initial_cols = 140
	c.initial_rows = 40
 
	c.use_ime = true
	-- c.use_dead_keys = false
	-- c.ime_preedit_rendering = "System"
	c.enable_wayland = false
 
	c.color_scheme = "Tokyo Night"
	c.adjust_window_size_when_changing_font_size = false
 
	c.font = wezterm.font_with_fallback({
		{ family = "D2Coding" },
		{ family = "JetBrainsMonoHangul Nerd Font Mono" },
	})
	c.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
	c.font_size = 12
 
	-- Slightly transparent and blurred background
	c.front_end = "WebGpu"
	c.freetype_load_flags = "NO_HINTING"
	c.freetype_load_target = "Light"
	-- c.freetype_render_target = "Normal"
	c.freetype_render_target = "HorizontalLcd"
	-- c.custom_block_glyphs = true
	c.cell_width = 1
	c.line_height = 1.15
 
	c.window_background_opacity = opacity
	c.macos_window_background_blur = blur
	c.use_fancy_tab_bar = false
	c.enable_tab_bar = true
	c.hide_tab_bar_if_only_one_tab = true
	c.tab_max_width = 120
	-- Removes the title bar, leaving only the tab bar. Keeps
	-- the ability to resize by dragging the window's edges.
	-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
	-- you want to keep the window controls visible and integrate
	-- them into the tab bar.
	c.window_decorations = "RESIZE"
	-- Sets the font for the window frame (tab bar)
	c.window_frame = {
		font = wezterm.font({ family = "D2Coding" }),
		font_size = 10,
		-- border_left_width = "4px",
		-- border_right_width = "4px",
		-- border_bottom_height = "4px",
		-- border_top_height = "4px",
	}
	c.window_padding = {
		left = 8,
		right = 8,
		top = 6,
		bottom = 0,
	}
	c.native_macos_fullscreen_mode = true
end
 
local function setup_basic_keys()
	c.keys = {
		{ key = "f", mods = CTRL .. "|" .. CMD, action = wezterm.action.ToggleFullScreen },
		-- Sends ESC + b and ESC + f sequence, which is used
		-- for telling your shell to jump back/forward.
		{
			-- When the left arrow is pressed
			key = "LeftArrow",
			-- With the "Option" key modifier held down
			mods = OPT,
			-- Perform this action, in this case - sending ESC + B
			-- to the terminal
			action = act.SendString("\x1bb"),
		},
		{
			key = "RightArrow",
			mods = OPT,
			action = act.SendString("\x1bf"),
		},
		{
			key = "w",
			mods = CMD,
			action = wezterm.action_callback(function(window, pane)
				local tab = pane:tab()
				local panes = tab:panes()
 
				if #panes >= 2 then
					window:perform_action(act.CloseCurrentPane({ confirm = false }), pane)
				else
					window:perform_action(act.CloseCurrentTab({ confirm = false }), pane)
				end
			end),
		},
		{
			key = "t",
			mods = CMD,
			action = act.SpawnTab("CurrentPaneDomain"),
		},
	}
end
-- Table mapping keypresses to actions
 
local tab_bg = "#111111"
local tab_fg = "#808080"
c.colors = {
	foreground = "white",
	background = "#111111",
	tab_bar = {
		-- The color of the strip that goes along the top of the window
		-- (does not apply when fancy tab bar is in use)
		background = tab_bg,
 
		-- The active tab is the one that has focus in the window
		active_tab = {
			-- The color of the background area for the tab
			bg_color = "#232b3d",
			-- The color of the text for the tab
			fg_color = "#c3c3c3",
			-- intensity = "Bold",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
 
		-- Inactive tabs are the tabs that do not have focus
		inactive_tab = {
			bg_color = tab_bg,
			fg_color = tab_fg,
			intensity = "Normal",
		},
 
		-- inactive_tab_hover = {
		-- 	bg_color = "#3b3052",
		-- 	fg_color = "#909090",
		-- },
 
		new_tab = {
			bg_color = tab_bg,
			fg_color = tab_fg,
		},
	},
}
 
local fps = 240
c.max_fps = fps
c.animation_fps = fps
c.default_cursor_style = "BlinkingBar"
c.cursor_blink_rate = 400
 
local function regsiter_smart_splits_multiplexer()
	local w = require("wezterm")
 
	-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
	local function is_vim(pane)
		-- this is set by the plugin, and unset on ExitPre in Neovim
		return pane:get_user_vars().IS_NVIM == "true"
	end
 
	local direction_keys = {
		h = "Left",
		j = "Down",
		k = "Up",
		l = "Right",
	}
 
	local function split_nav(resize_or_move, key)
		return {
			key = key,
			mods = resize_or_move == "resize" and OPT or CTRL,
			action = w.action_callback(function(win, pane)
				if is_vim(pane) then
					-- pass the keys through to vim/nvim
					win:perform_action({
						SendKey = { key = key, mods = resize_or_move == "resize" and OPT or CTRL },
					}, pane)
				else
					if resize_or_move == "resize" then
						win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
					else
						win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
					end
				end
			end),
		}
	end
 
	table.insert(c.keys, split_nav("move", "h"))
	table.insert(c.keys, split_nav("move", "j"))
	table.insert(c.keys, split_nav("move", "k"))
	table.insert(c.keys, split_nav("move", "l"))
	table.insert(c.keys, split_nav("resize", "h"))
	table.insert(c.keys, split_nav("resize", "j"))
	table.insert(c.keys, split_nav("resize", "k"))
	table.insert(c.keys, split_nav("resize", "l"))
end
 
local function register_split_multiplexing()
	local w = require("wezterm")
 
	local function split_nav(is_horizontal)
		local mods = CMD .. (is_horizontal and "|" .. OPT or "")
		return {
			key = "0",
			mods = mods,
			action = w.action_callback(function(win, pane)
				if is_horizontal then
					win:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
				else
					win:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
				end
			end),
		}
	end
 
	table.insert(c.keys, split_nav(true))
	table.insert(c.keys, split_nav(false))
end
setup_basic_keys()
setup_core()
regsiter_smart_splits_multiplexer()
register_split_multiplexing()
 
return c
