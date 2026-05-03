local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- config.default_domain = 'WSL:Debian'
config.default_prog = { "wsl.exe", "-d", "Debian", "--cd", "~" }
config.colors = {
  background = "#1A1A1A",
}
config.window_close_confirmation = "NeverPrompt"

wezterm.on('mux-is-process-stateful', function(proc)
  return false
end)

config.keys = {
  -- Copy
  {
    key = 'c',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local selection = window:get_selection_text_for_pane(pane)
      if selection ~= '' then
        window:perform_action(wezterm.action.CopyTo 'Clipboard', pane)
      else
        window:perform_action(wezterm.action.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end),
  },
  -- Paste
  {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config