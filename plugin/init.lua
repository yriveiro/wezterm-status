local insert = table.insert
local string = string

---@class Config: Wezterm
local wezterm = require 'wezterm'

--- Merges two tables recursively
---@package
---@param t1 table The first table to merge into
---@param t2 table The second table to merge from
---@return table The merged table
local function tableMerge(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == 'table' then
      if type(t1[k] or false) == 'table' then
        tableMerge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

--- Returns the battery icon based on the battery level
---@package
---@return string The battery icon corresponding to the bucket
local function battery_level()
  ---@type BatteryInfo
  local battery_info = wezterm.battery_info()

  if battery_info == nil or #battery_info == 0 then
    wezterm.log_error 'Battery info is unknown'
    return ' ' .. wezterm.nerdfonts.fa_question_circle
  end

  local level = tonumber(battery_info[1].state_of_charge)

  if level < 0.0 or level > 1.0 then
    wezterm.log_error 'Battery level must be between 0.0 and 1.0'
    return ' ' .. wezterm.nerdfonts.fa_question_circle
  end

  local bucket = math.ceil(level * 4)

  if bucket == 1 then
    return ' ' .. wezterm.nerdfonts.fa_battery_empty
  elseif bucket == 2 then
    return ' ' .. wezterm.nerdfonts.fa_battery_quarter
  elseif bucket == 3 then
    return ' ' .. wezterm.nerdfonts.fa_battery_three_quarters
  end

  return ' ' .. wezterm.nerdfonts.fa_battery_full
end

---@class WeztermStatusConfig
---@field mode {enabled: boolean, modes: table}
---@field battery {enabled: boolean}
---@field hostname {enabled: boolean}
---@field cwd {enabled: boolean, tilde_prefix: boolean}
---@field date {enabled: boolean, format: string}
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
    },
    date = {
      enabled = true,
      icon = wezterm.nerdfonts.md_clock_time_three_outline,
      format = '%H:%M:%S',
    },
  },
}

---@alias WeztermStatusCellAttributes[]
---| "Bold"
---| "Curly"
---| "Dashed"
---| "Dotted"
---| "Double"
---| "Half"
---| "Italic"
---| "NoItalic"
---| "NoUnderline"
---| "Normal"
---| "Single"

---@class WeztermStatusCells
---@field private cells table Storage for the cells.
---@field protected attrs WeztermStatusCellAttributes Attributes available to format cell text.
---@field new fun(self: WeztermStatusCells): WeztermStatusCells Creates a new Cells instance.
---@field push fun(self: WeztermStatusCells, background: string, foreground: string, text: string, attributes: string[]?): nil Pushes a cell to with specified background color, foreground color, text, and optional attributes..
---@field draw fun(self: WeztermStatusCells): FormatItem[] Returns a FormatItem array for wezterm.format consume.
---@field clear fun(self: WeztermStatusCells): nil Clears Cells instance.
local Cells = {}

--- Creates a new Cells instance.
---@return WeztermStatusCells
---@package
---@nodiscard
function Cells:new()
  return setmetatable({
    cells = {},
    attrs = {
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
    },
  }, {
    __index = self,
    __newindex = function(t, k, v)
      rawset(t.cells, #t.cells + 1, v)
    end,
  })
end

--- Pushes a cell with specified background color, foreground color, text, and optional attributes.
---@package
---@param background string The background color
---@param foreground string The foreground color
---@param text string The text to display
---@param attributes string[]? Optional attributes for the text
function Cells:push(background, foreground, text, attributes)
  if attributes then
    for _, attr in ipairs(attributes) do
      if self.attrs[attr] then
        for k, v in pairs(self.attrs[attr]) do
          insert(self, { Attribute = { [k] = v } })
        end
      else
        wezterm.log_error("attribute '" .. attr .. "' is non-existent")
      end
    end
  end

  insert(self, { Background = { Color = background } })
  insert(self, { Foreground = { Color = foreground } })
  insert(self, { Text = text })
  insert(self, 'ResetAttributes')
end

--- Returns a FormatItem array for wezterm.format consume.
---@package
---@return FormatItem[] The formatted items
function Cells:draw()
  return self.cells
end

--- Clears the Cells instance.
---@package
function Cells:clear()
  self.cells = {}
end

---@class WeztermStatus
---@field protected config WeztermStatusConfig Internal plugin config
---@field cells table All cells of the status bar
local M = {}

--- Applies configuration to Wezterm
---@param wezterm_config Config
---@param opts? WeztermStatusConfig
function M.apply_to_config(wezterm_config, opts)
  config = tableMerge(config, opts or {})
end

wezterm.on('update-status', function(window, pane)
  ---@type TabBarColor
  local palette = window:effective_config().resolved_palette.tab_bar.active_tab
  local cells = Cells:new()

  cells:push(palette.fg_color, palette.bg_color, config.ui.separators.arrow_solid_right)

  if config.cells.mode.enabled then
    local kt = window:active_key_table()

    if not kt then
      cells:push(
        palette.bg_color,
        palette.fg_color,
        ' ' .. wezterm.nerdfonts.cod_home .. config.ui.separators.arrow_thin_right,
        { 'Bold' }
      )
    end

    if config.cells.mode.modes[kt] then
      cells:push(
        palette.bg_color,
        palette.fg_color,
        config.cells.mode.modes[kt] .. config.ui.separators.arrow_thin_right
      )
    end
  end

  if config.cells.battery.enabled then
    cells:push(
      palette.bg_color,
      palette.fg_color,
      battery_level() .. config.ui.separators.arrow_thin_right
    )
  end

  if config.cells.hostname.enabled then
    local uri = pane:get_current_working_dir()

    if uri then
      if type(uri) == 'userdata' then
        --- Uri is userdata type, will never work with diagnostic type checking.
        ---@diagnostic disable-next-line: undefined-field
        local hostname = uri.host or wezterm.hostname()

        cells:push(
          palette.bg_color,
          palette.fg_color,
          ' ' .. hostname .. config.ui.separators.arrow_thin_right
        )
      else
        wezterm.log_warn "this version of Wezterm doesn't support URL objects"
      end
    end
  end

  if config.cells.cwd.enabled then
    ---@type string|nil
    local uri = pane:get_current_working_dir()

    if uri then
      if type(uri) == 'userdata' then
        local path = uri.file_path ---@diagnostic disable-line

        if config.cells.cwd.tilde_prefix then
          path = path:gsub(os.getenv 'HOME', '~')
        end

        cells:push(
          palette.bg_color,
          palette.fg_color,
          string.format(' %s%s', path, config.ui.separators.arrow_thin_right)
        )
      else
        wezterm.log_warn "this version of Wezterm doesn't support URL objects"
      end
    end
  end

  if config.cells.date.enabled then
    cells:push(
      palette.bg_color,
      palette.fg_color,
      ' '
        .. config.cells.date.icon
        .. ' '
        .. wezterm.strftime(config.cells.date.format)
        .. config.ui.separators.arrow_thin_right
    )
  end

  window:set_right_status(wezterm.format(cells:draw()))
  cells:clear()
end)

return M
