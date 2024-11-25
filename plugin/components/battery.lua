local wezterm = require 'wezterm'
local nerdfonts = wezterm.nerdfonts

local M = {}

--- Returns the battery icon based on the battery state of charge
---@return string The battery icon corresponding to the charge level
function M.battery_level()
  local info = wezterm.battery_info()[1]

  if not info then
    return ' ' .. nerdfonts.fa_question_circle
  end

  local level = info.state_of_charge
  if level < 0.0 or level > 1.0 then
    return ' ' .. nerdfonts.fa_question_circle
  end

  if level <= 0.25 then
    return ' ' .. nerdfonts.fa_battery_empty
  end
  if level <= 0.5 then
    return ' ' .. nerdfonts.fa_battery_quarter
  end
  if level <= 0.75 then
    return ' ' .. nerdfonts.fa_battery_three_quarters
  end

  return ' ' .. nerdfonts.fa_battery_full
end

return M
