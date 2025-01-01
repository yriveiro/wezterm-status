local wezterm = require 'wezterm'
local nerdfonts = wezterm.nerdfonts

local M = {}

---Check if the `kubectl` binary exists in typical paths for the current platform.
---This function guesses the possible locations of the `kubectl` binary based on
---the operating system (Windows, Linux, macOS).
---If `kubectl` is not found in any of the guessed paths, it returns `nil`.
---@return string|nil The path to the `kubectl` binary if found, otherwise `nil`.
function M.find_kubectl()
  local os_name = package.config:sub(1, 1) == '\\' and 'windows' or 'unix'

  local paths = {}

  if os_name == 'windows' then
    paths = {
      'C:\\Program Files\\Kubernetes\\kubectl.exe',
      'C:\\Program Files (x86)\\Kubernetes\\kubectl.exe',
      'C:\\Windows\\System32\\kubectl.exe',
      'C:\\kubectl.exe',
    }
  else
    paths = {
      '/usr/local/bin/kubectl',
      '/usr/bin/kubectl',
      '/bin/kubectl',
      '/opt/homebrew/bin/kubectl',
    }
  end

  for _, path in ipairs(paths) do
    local file = io.open(path, 'r')
    if file then
      file:close()
      return path
    end
  end

  return nil
end

---Get the current Kubernetes context using `kubectl`.
---Executes the `kubectl config current-context` command and returns the current Kubernetes context.
---@param kubectl_path string The full path to the `kubectl` binary.
---@return string The current Kubernetes context prefixed with a Kubernetes icon (from Nerd Fonts), or an empty string if the command fails.
function M.get_current_context(kubectl_path)
  local handle = io.popen(kubectl_path .. ' config current-context 2>&1')
  if not handle then
    return ''
  end

  -- Read the output
  local result = handle:read '*a'
  local success, _, code = handle:close()

  -- Trim whitespace from result
  result = result:gsub('^%s+', ''):gsub('%s+$', '')

  -- Return nil if command failed
  if code ~= 0 then
    return ''
  end

  return code == 0 and nerdfonts.md_kubernetes .. ' ' .. result or ''
end

return M
