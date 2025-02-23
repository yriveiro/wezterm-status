---@meta

--[[
@module 'wezterm-status'
@description A module for configuring and customizing Wezterm's status bar

This module provides functionality to:
- Configure status bar cells with various information displays
- Show battery status with dynamic icons
- Display the current working directory
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

local NAME = 'httpssCssZssZsgithubsDscomsZsyriveirosZswezterm-status'

local wezterm = require 'wezterm' --[[@as Wezterm]]

--- Prepare for loading sub modules inside the plugin. Werzterm doesn't handle
--- this natively.
---
local separator = wezterm.target_triple:match 'windows' and '\\' or '/'
local root_path = wezterm.plugin.list()[1].plugin_dir:match('(.*)' .. separator)
  .. separator
  .. NAME
  .. separator
  .. 'plugin'
  .. separator

package.path = package.path
  .. ';'
  .. root_path
  .. '?.lua'
  .. ';'
  .. root_path
  .. '?/init.lua'

local Battery = require 'components.battery'
local CWD = require 'components.cwd'
local Cells = require 'cells'
local K8S = require 'components.k8s'
local Utils = require 'utils'

local gsub = string.gsub
local ipairs = ipairs
local type = type

local format = wezterm.format
local strftime = wezterm.strftime
local hostname = wezterm.hostname
local log_warn = wezterm.log_warn
local nerdfonts = wezterm.nerdfonts

---@type WeztermStatusConfig
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
        normal = ' ' .. nerdfonts.cod_home,
        copy_mode = ' ' .. nerdfonts.cod_copy,
        search_mode = ' ' .. nerdfonts.cod_search,
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
    workspace = {
      enabled = false,
      icon = wezterm.nerdfonts.md_television_guide,
    },
    k8s_context = {
      enabled = false,
      kubectl_path = K8S.find_kubectl(),
    },
  },
}

---@class WeztermStatus
---@field protected config WeztermStatusConfig Internal plugin configuration
---@field cells table All cells of the status bar
local M = {}

--- Applies configuration to Wezterm's status bar
---@param wezterm_config Config The Wezterm configuration table
---@param opts? WeztermStatusConfig Optional configuration overrides
function M.apply_to_config(wezterm_config, opts)
  config = Utils.table_merge(config, opts or {})

  local user_active_tab = wezterm_config.colors
    and wezterm_config.colors.tab_bar
    and wezterm_config.colors.tab_bar.active_tab

  config.ui.theme = user_active_tab
    or config.ui.theme
    or {
      bg_color = '#88C0D0',
      fg_color = '#2E3440',
      intensity = 'Normal',
      underline = 'None',
      italic = false,
      strikethrough = false,
    }

  if not user_active_tab then
    wezterm.log_warn(
      "Wezterm-Status: No 'config.colors.tab_bar.active_tab' detected. "
        .. "Falling back to the plugin's internal theme. "
        .. "You can customize it via plugin configuration 'config.ui.theme'."
        .. 'more info: https://github.com/yriveiro/wezterm-status/tree/main?tab=readme-ov-file#setup'
    )
  end
end

-- Register status bar update handler
wezterm.on('update-status', function(window, pane)
  local cells = Cells:new()
  local config_cells = config.cells
  local separators = config.ui.separators
  local thin_right = separators.arrow_thin_right

  local bg = config.ui.theme.bg_color
  local fg = config.ui.theme.fg_color

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
    cells:push(bg, fg, Battery.battery_level() .. thin_right)
  end

  local uri = pane:get_current_working_dir() --[[@as CWD]]

  if uri and type(uri) == 'userdata' then
    if config_cells.hostname.enabled then
      cells:push(bg, fg, ' ' .. (uri.host --[[@as CWD]] or hostname()) .. thin_right)
    end
    if config_cells.cwd.enabled then
      cells:push(
        bg,
        fg,
        ' '
          .. CWD.cwd(uri --[[@as CWD]], config_cells.cwd)
          .. thin_right
      )
    end
  elseif uri then
    log_warn "this version of Wezterm doesn't support URL objects"
  end

  if config_cells.workspace.enabled then
    cells:push(
      bg,
      fg,
      ' ' .. config_cells.workspace.icon .. ' ' .. window:active_workspace() .. thin_right
    )
  end

  if config_cells.k8s_context.enabled then
    cells:push(
      bg,
      fg,
      ' ' .. K8S.get_current_context(config_cells.k8s_context.kubectl_path) .. thin_right
    )
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
