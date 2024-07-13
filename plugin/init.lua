---@class Config: Wezterm
local wezterm = require 'wezterm'

local M = {}

---@param config Config
---@param opts? Opts
function M.apply_to_config(config, opts)
  opts = opts or {}
  config = config

  wezterm.log_info 'status plugin loaded'
end

return M
