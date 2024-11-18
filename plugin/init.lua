---@meta

--[[ 
@module 'wezterm-status'
@description A module for configuring and customizing Wezterm's status bar

This module provides functionality to:
- Configure status bar cells with various information displays
- Show battery status with dynamic icons
- Display current working directory
- Show active mode indicators
- Show current time and hostname
- Apply consistent styling across status elements

@example Basic usage:
```lua
wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-status')
  .apply_to_config(config)
```

@example Custom configuration:
```lua
wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-status')
  .apply_to_config(config, {
    cells = {
      battery = { enabled = false },
      date = {
        enabled = true,
        format = '%H:%M'
      }
    }
  })
```
]]

local concat = table.concat
local get_env = os.getenv
local gsub = string.gsub
local insert = table.insert
local ipairs = ipairs
local os = os
local pairs = pairs
local rawset = rawset
local setmetatable = setmetatable
local string = string
local tonumber = tonumber
local type = type

---@class Config: Wezterm
local wezterm = require 'wezterm'
local log_error = wezterm.log_error
local format = wezterm.format
local strftime = wezterm.strftime
local hostname = wezterm.hostname
local log_warn = wezterm.log_warn
local nerdfonts = wezterm.nerdfonts

--- Merges two tables recursively with depth tracking to prevent stack overflow
---@param t1 table The first table to merge into
---@param t2 table The second table to merge from
---@return table The merged table
local function tableMerge(t1, t2)
  -- Use recursion with depth tracking instead of stack
  local function merge(dest, src, depth)
    if depth > 100 then
      return dest
    end

    for k, v in pairs(src) do
      if type(v) == 'table' then
        dest[k] = type(dest[k]) == 'table' and dest[k] or {}
        merge(dest[k], v, depth + 1)
      else
        dest[k] = v
      end
    end
    return dest
  end
  return merge(t1, t2, 0)
end

--- Returns the battery icon based on the battery state of charge
---@return string The battery icon corresponding to the charge level
local function battery_level()
  local info = wezterm.battery_info()[1]
  if not info then
    return ' ' .. wezterm.nerdfonts.fa_question_circle
  end

  local level = info.state_of_charge
  if level < 0.0 or level > 1.0 then
    return ' ' .. wezterm.nerdfonts.fa_question_circle
  end

  if level <= 0.25 then
    return ' ' .. wezterm.nerdfonts.fa_battery_empty
  end
  if level <= 0.5 then
    return ' ' .. wezterm.nerdfonts.fa_battery_quarter
  end
  if level <= 0.75 then
    return ' ' .. wezterm.nerdfonts.fa_battery_three_quarters
  end

  return ' ' .. wezterm.nerdfonts.fa_battery_full
end

---@class WeztermUiConfig
---@field separators SeparatorConfig Visual separators used in the status bar

---@class SeparatorConfig
---@field arrow_solid_left string Unicode character for solid left arrow
---@field arrow_solid_right string Unicode character for solid right arrow
---@field arrow_thin_left string Unicode character for thin left arrow
---@field arrow_thin_right string Unicode character for thin right arrow

---@class WeztermStatusCellsConfig
---@field mode ModeConfig Mode indicator configuration
---@field battery BatteryConfig Battery indicator configuration
---@field hostname HostnameConfig Hostname display configuration
---@field cwd CwdConfig Current working directory configuration
---@field date DateConfig Date and time display configuration

---@class ModeConfig
---@field enabled boolean Whether to show mode indicator
---@field modes table<string, string> Mapping of mode names to their icons

---@class BatteryConfig
---@field enabled boolean Whether to show battery status

---@class HostnameConfig
---@field enabled boolean Whether to show hostname

---@class CwdConfig
---@field enabled boolean Whether to show current directory
---@field tilde_prefix boolean Whether to replace home directory with tilde
---@field path_aliases PathAliasConfig[] Array of path alias configurations

---@class DateConfig
---@field enabled boolean Whether to show date/time
---@field icon string Icon to show before time
---@field format string strftime format string

---@class PathAliasConfig
---@field pattern string Pattern to match in the path
---@field replacement string Text to replace the matched pattern with

---@class WeztermStatusConfig
---@field ui WeztermUiConfig UI-related configuration
---@field cells WeztermStatusCellsConfig Status cells configuration
local config = {
  ui = {
    separators = {
      arrow_solid_left = ' \u{e0b0}',
      arrow_solid_right = ' \u{e0b2}',
      arrow_thin_left = ' \u{e0b1}',
      arrow_thin_right = ' \u{e0b3}',
    },
  },
  cells = {
    mode = {
      enabled = true,
      modes = {
        normal = ' ' .. wezterm.nerdfonts.cod_home,
        copy_mode = ' ' .. wezterm.nerdfonts.cod_copy,
        search_mode = ' ' .. wezterm.nerdfonts.cod_search,
      },
    },
    battery = {
      enabled = true,
    },
    hostname = {
      enabled = true,
    },
    cwd = {
      enabled = true,
      tilde_prefix = true,
      path_aliases = {
        -- Example aliases
        -- { pattern = "/home/user/projects", replacement = "📂" },
        -- { pattern = "/var/log", replacement = "📑" }
      },
    },
    date = {
      enabled = true,
      icon = wezterm.nerdfonts.md_clock_time_three_outline,
      format = '%H:%M:%S',
    },
  },
}

---@alias WeztermStatusCellAttributes
---| "Bold" # Bold text intensity
---| "Curly" # Curly underline style
---| "Dashed" # Dashed underline style
---| "Dotted" # Dotted underline style
---| "Double" # Double underline style
---| "Half" # Half text intensity
---| "Italic" # Italic text style
---| "NoItalic" # Disable italic style
---| "NoUnderline" # Remove underline
---| "Normal" # Normal text intensity
---| "Single" # Single underline style

---@class WeztermStatusCells
---@field private cells table Storage for the cells
---@field protected attrs WeztermStatusCellAttributes Available text formatting attributes
---@field new fun(self: WeztermStatusCells): WeztermStatusCells Creates a new Cells instance
---@field push fun(self: WeztermStatusCells, background: string, foreground: string, text: string, attributes: string[]?): nil Adds a new cell with specified styling
---@field draw fun(self: WeztermStatusCells): FormatItem[] Returns formatted items for rendering
---@field clear fun(self: WeztermStatusCells): nil Clears all cells
local Cells = {}
local attrs = {
  Bold = { Intensity = 'Bold' },
  Curly = { Underline = 'Curly' },
  Dashed = { Underline = 'Dashed' },
  Dotted = { Underline = 'Dotted' },
  Double = { Underline = 'Double' },
  Half = { Intensity = 'Half' },
  Italic = { Italic = true },
  NoItalic = { Italic = false },
  NoUnderline = { Underline = 'None' },
  Normal = { Intensity = 'Normal' },
  Single = { Underline = 'Single' },
}

--- Creates a new Cells instance for managing status bar cells
---@return WeztermStatusCells
---@package
---@nodiscard
function Cells:new()
  return setmetatable({
    cells = {},
    attrs = attrs,
  }, {
    __index = self,
    __newindex = function(t, k, v)
      rawset(t.cells, #t.cells + 1, v)
    end,
  })
end

--- Pushes a new cell to the status bar with specified styling
---@package
---@param background string The background color
---@param foreground string The foreground color
---@param text string The text to display
---@param attributes string[]? Optional text formatting attributes
function Cells:push(background, foreground, text, attributes)
  if attributes then
    for _, attr in ipairs(attributes) do
      if not self.attrs[attr] then
        log_error(
          string.format(
            "Invalid attribute '%s'. Valid attributes: %s",
            attr,
            concat(vim.tbl_keys(self.attrs), ', ')
          )
        )
        return
      end

      local attr_data = self.attrs[attr]
      if attr_data then
        for k, v in pairs(attr_data) do
          insert(self, { Attribute = { [k] = v } })
        end
      else
        log_error("attribute '" .. attr .. "' is non-existent")
      end
    end
  end

  insert(self, { Background = { Color = background } })
  insert(self, { Foreground = { Color = foreground } })
  insert(self, { Text = text })
  insert(self, 'ResetAttributes')
end

--- Returns a FormatItem array for wezterm.format to consume
---@package
---@return FormatItem[] The formatted items for rendering
function Cells:draw()
  return self.cells
end

--- Clears all cells from the status bar
---@package
function Cells:clear()
  self.cells = {}
end

---@class WeztermStatus
---@field protected config WeztermStatusConfig Internal plugin configuration
---@field cells table All cells of the status bar
local M = {}

--- Applies configuration to Wezterm's status bar
---@param wezterm_config Config The Wezterm configuration table
---@param opts? WeztermStatusConfig Optional configuration overrides
function M.apply_to_config(wezterm_config, opts)
  config = tableMerge(config, opts or {})
end

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
      path = gsub(path, alias.pattern, alias.replacement)
    end
  end

  return path
end

-- Register status bar update handler
wezterm.on('update-status', function(window, pane)
  local cells = Cells:new()
  local config_cells = config.cells
  local separators = config.ui.separators
  local palette = window:effective_config().resolved_palette.tab_bar.active_tab
  local bg = palette.bg_color
  local fg = palette.fg_color
  local thin_right = separators.arrow_thin_right

  cells:push(fg, bg, separators.arrow_solid_right)

  if config_cells.mode.enabled then
    local kt = window:active_key_table()

    if not kt then
      cells:push(bg, fg, ' ' .. nerdfonts.cod_home .. thin_right, { 'Bold' })
    end
    local mode = config_cells.mode.modes[kt]

    if mode then
      cells:push(bg, fg, mode .. thin_right)
    end
  end

  if config_cells.battery.enabled then
    cells:push(bg, fg, battery_level() .. thin_right)
  end

  local uri = pane:get_current_working_dir()

  if uri and type(uri) == 'userdata' then
    if config_cells.hostname.enabled then
      cells:push(bg, fg, ' ' .. (uri.host or hostname()) .. thin_right)
    end

    if config_cells.cwd.enabled then
      local path = uri.file_path

      if config_cells.cwd.tilde_prefix then
        path = gsub(path, get_env 'HOME', '~')
      end

      path = apply_path_aliases(path, config_cells.cwd.path_aliases)

      cells:push(bg, fg, ' ' .. path .. thin_right)
    end
  elseif uri then
    log_warn "this version of Wezterm doesn't support URL objects"
  end

  if config_cells.date.enabled then
    cells:push(
      bg,
      fg,
      ' '
        .. config_cells.date.icon
        .. ' '
        .. strftime(config_cells.date.format)
        .. thin_right
    )
  end

  window:set_right_status(format(cells:draw()))

  cells:clear()
end)

return M
