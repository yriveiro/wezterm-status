local insert = table.insert

---@class Config: Wezterm
local wezterm = require 'wezterm'

---@package
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

---Returns the battery icon based on the battery level
---@package
---@return string string with the battery icon corresponding to the bucket
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
---@field mode {enabled: boolean}
---@field battery {enabled: boolean}
---@field hostname {enabled: boolean}
local config = {
  mode = {
    enabled = true,
    index = 0,
    callback = nil,
  },
  battery = {
    enabled = true,
    index = 1,
    callback = nil,
  },
  hostname = {
    enabled = true,
    index = 2,
    callback = nil,
  },
  cwd = {
    enabled = true,
    index = 3,
    callback = nil,
  },
  date = {
    enabled = true,
    index = 4,
    callback = nil,
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

---Creates a new Cells instance.
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

---@package
function Cells:push(background, foreground, text, attributes)
  if attributes then
    for _, attr in ipairs(attributes) do
      if self.attrs[attr] then
        local t = { Attribute = {} }
        for k, v in pairs(self.attrs[attr]) do
          t.Attribute[k] = v
          insert(self, t)
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

---@package
function Cells:draw()
  return self.cells
end

---@package
function Cells:clear()
  self.cells = {}
end

---@class WeztermStatus
---@field protected config WeztermStatusConfig internal plugin config
---@field cells table all cells of the status bar
local M = {}

M.arrow_solid_left = ''
M.arrow_thin_left = ''
M.arrow_solid_right = ''
M.arrow_thin_right = ''

local modes = {
  normal = ' ' .. wezterm.nerdfonts.cod_home,
  copy_mode = ' ' .. wezterm.nerdfonts.cod_copy,
  search_mode = ' ' .. wezterm.nerdfonts.cod_search,
  -- window_mode = { text = ' 󱂬 WINDOW ', bg = colors[6], pad = 7 },
  -- font_mode = {
  --   text = ' 󰛖 FONT ',
  --   bg = colors[6] or colors[8],
  --   pad = 7,
  -- },
  -- lock_mode = { text = '  LOCK ', bg = colors[8], pad = 0 },
}

---@param wezterm_config Config
---@param opts? WeztermStatusConfig
function M.apply_to_config(wezterm_config, opts)
  config = tableMerge(config, opts or {})
end

wezterm.on('update-status', function(window, pane)
  ---@type TabBarColor
  local palette = window:effective_config().resolved_palette.tab_bar.active_tab
  local cells = Cells:new()

  cells:push(palette.fg_color, palette.bg_color, M.arrow_solid_right)

  if config.mode.enabled then
    local kt = window:active_key_table()

    if not kt then
      cells:push(
        palette.bg_color,
        palette.fg_color,
        ' ' .. wezterm.nerdfonts.cod_home,
        { 'Bold' }
      )
    end

    if modes[kt] then
      cells:push(palette.bg_color, palette.fg_color, modes[kt])
    end

    cells:push(palette.bg_color, palette.fg_color, ' ' .. M.arrow_thin_right)
  end

  if config.battery.enabled then
    cells:push(palette.bg_color, palette.fg_color, battery_level())
    cells:push(palette.bg_color, palette.fg_color, ' ' .. M.arrow_thin_right)
  end

  --
  -- if M.config.hostname.enabled then
  --   local uri = pane:get_current_working_dir()
  --
  --   if uri then
  --     if type(uri) == 'userdata' then
  --       local hostname = uri.host or wezterm.hostname()
  --
  --       M.push(palette.bg_color, palette.fg_color, ' ' .. hostname)
  --       M.push(palette.bg_color, palette.fg_color, ' ' .. M.arrow_thin_right)
  --     else
  --       wezterm.log_warn "this version of Wezterm doesn't support URL objects"
  --     end
  --   end
  -- end
  --
  -- if M.config.cwd.enabled then
  --   ---@type userdata|string
  --   local uri = pane:get_current_working_dir()
  --
  --   if uri then
  --     local cwd = ''
  --
  --     if type(uri) == 'userdata' then
  --       M.push(palette.bg_color, palette.fg_color, ' ' .. uri.file_path)
  --       M.push(palette.bg_color, palette.fg_color, ' ' .. M.arrow_thin_right)
  --     else
  --       wezterm.log_warn "this version of Wezterm doesn't support URL objects"
  --     end
  --   end
  -- end
  --

  -- wezterm.log_info(cells:draw())

  window:set_right_status(wezterm.format(cells:draw()))

  cells:clear()
end)

------Pushes a section to `M.cells` with specified background color, foreground color, text, and optional attributes.
------```lua
------M.push("red", "blue", "Hello World", {"bold", "italic"})
------```
------@param background string The background color to be applied.
------@param foreground string The foreground color to be applied.
------@param text string The text to be inserted.
------@param attributes? table Optional. A table of attributes to be applied.
---function M.push(background, foreground, text, attributes)
---  if attributes then
---    for _, attr in ipairs(attributes) do
---      if cell_attrs[attr] then
---        local t = { Attribute = {} }
---        for k, v in pairs(cell_attrs[attr]) do
---          t.Attribute[k] = v
---          insert(M.cells, t)
---        end
---      else
---        wezterm.log_error("attribute '" .. attr .. "' is non-existent")
---      end
---    end
---  end
---
---  insert(M.cells, { Background = { Color = background } })
---  insert(M.cells, { Foreground = { Color = foreground } })
---  insert(M.cells, { Text = text })
---  insert(M.cells, 'ResetAttributes')
---end

return M
