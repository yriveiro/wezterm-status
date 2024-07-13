---@module 'wezterm'
---@module 'status'

---@class Config
local wezterm = require 'wezterm'

---@class Status
local Status = require 'status.status'

local M = {}

---@param config Config
---@param opts? Opts
function M.apply_to_config(config, opts)
  wezterm.log_info 'status plugin loaded'
end

return M
