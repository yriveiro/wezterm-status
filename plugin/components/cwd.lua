local HOME = os.getenv 'HOME' or ''
local gsub = string.gsub

local wezterm = require 'wezterm'
local nerdfonts = wezterm.nerdfonts

local Utils = require 'utils'

local M = {}

--- Applies configured path aliases to a path string
---@param path string The original path
---@param aliases PathAliasConfig[] Array of path alias configurations
---@return string The path with aliases applied
local function apply_path_aliases(path, aliases)
  if not aliases then
    return path
  end

  for _, alias in ipairs(aliases) do
    if alias.pattern and alias.replacement then
      path = gsub(path, Utils.escape_pattern(alias.pattern), alias.replacement)
    end
  end

  return path
end

--- Current working Directory
---@param uri CWD The raw current Directory.
---@param cnf? CwdConfig Current working Directory custom configurations.
---@return string The cwd parsed
function M.cwd(uri, cnf)
  local path = uri.file_path

  if cnf and cnf.tilde_prefix then
    path = gsub(path, HOME, '~')
  end

  if cnf and cnf.path_aliases then
    path = apply_path_aliases(path, cnf.path_aliases)
  end

  return path
end

return M
