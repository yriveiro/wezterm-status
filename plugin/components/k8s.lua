local wezterm = require 'wezterm'
local nerdfonts = wezterm.nerdfonts

local M = {}

--- Checks if kubectl command-line tool exists in system PATH
---@return boolean true if kubectl exists, false if it doesn't
function M.kubectl_exists()
  -- Early check for Windows vs Unix-like systems
  local isWindows = package.config:sub(1, 1) == '\\'
  local command = isWindows and 'where ' or 'which '

  -- Try to execute the command
  local handle, err = io.popen(command .. 'kubectl')

  if not handle then
    -- If we couldn't even execute the command, return error
    return false
  end

  -- Read output and close handle
  local result = handle:read '*a'
  local success, _, code = handle:close()

  -- Ensure we return an integer (0 for success, 1 for failure)
  -- If code is nil or non-zero, return 1
  return code == 0 and true or false
end

--- Gets the current kubectl context
---@return string|nil current_context The current kubectl context, nil if command fails
---@return integer exit_code The command exit code (0 for success, non-zero for failure)
function M.get_current_context()
  -- Execute kubectl command
  local handle = io.popen 'kubectl config current-context 2>&1'

  if not handle then
    return nil, 1
  end

  -- Read the output
  local result = handle:read '*a'
  local success, _, code = handle:close()

  -- Trim whitespace from result
  result = result:gsub('^%s+', ''):gsub('%s+$', '')

  -- Return nil if command failed
  if code ~= 0 then
    return nil, code
  end

  return nerdfonts.md_kubernetes .. ':' .. result, code
end
