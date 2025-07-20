local wezterm = require 'wezterm'
local act = wezterm.action

-- Always start Starship
return {
    default_prog = { "starship", "init", "fish", "--print-full-init" },
    -- or for bash/zsh:
    -- default_prog = { "starship", "init", "bash", "--print-full-init" },
    keys = {
      {
        key = 'c',
        mods = 'CTRL',
        action = wezterm.action_callback(function(win, pane)
          local has_selection = win:get_selection_text_for_pane(pane) ~= ""
          if has_selection then
            act.CopyTo 'Clipboard'
          else
            act.SendKey { key = 'c', mods = 'CTRL' }  -- sends SIGINT
          end
        end),
      },
    },
}