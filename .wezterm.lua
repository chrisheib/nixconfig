local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Always start Starship
return {
    -- default_prog = { "starship", "init", "fish", "--print-full-init" },
    -- or for bash/zsh:
    -- default_prog = { "starship", "init", "bash", "--print-full-init" },
    font = wezterm.font 'JetBrainsMono Nerd Font'
    keys = {
        key = 'c',
        mods = 'CTRL',
        action = wezterm.action_callback(
            function(win, pane)
                local has_selection = win:get_selection_text_for_pane(pane) ~= ""
                if has_selection then
                    act.CopyTo 'Clipboard'
                else
                    act.SendKey { key = 'c', mods = 'CTRL' }  -- sends SIGINT
                end
            end
        )
    }
}