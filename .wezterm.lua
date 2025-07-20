local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Always start Starship
-- default_prog = { "starship", "init", "fish", "--print-full-init" },
-- or for bash/zsh:
-- default_prog = { "starship", "init", "bash", "--print-full-init" },
config.font = wezterm.font 'JetBrainsMono Nerd Font';
config.font_size = 11;
config.keys = {
    {
        key = 'c',
        mods = 'CTRL',
        action = wezterm.action_callback(
            function(window, pane)
                local selection_text = window:get_selection_text_for_pane(pane)
                local is_selection_active = string.len(selection_text) ~= 0
                if is_selection_active then
                    window:perform_action(wezterm.action.CopyTo('ClipboardAndPrimarySelection'), pane)
                else
                    window:perform_action(wezterm.action.SendKey { key = 'c', mods = 'CTRL' }, pane)
                end
            end
        )
    },
    {
        key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'
    },
    {
        key = 'Backspace', mods = 'CTRL', action = act.SendKey { key = 'w', mods = 'CTRL' }
    },
    {
        key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain'
    },
    {
        key = 'w', mods = 'CTRL', action = wezterm.action.CloseCurrentTab { confirm = true },
    },
};
config.initial_rows = 49;
config.initial_cols = 110;
config.enable_scroll_bar = true;
config.scrollback_lines = 10000;
config.hide_tab_bar_if_only_one_tab = true;
return config
