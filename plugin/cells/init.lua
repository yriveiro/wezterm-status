---@class Config: Wezterm
local wezterm = require 'wezterm'

--- Cache methods for fast access
local concat = table.concat
local log_error = wezterm.log_error
local rawset = rawset
local setmetatable = setmetatable
local insert = table.insert

local M = {}

---@type WeztermStatusCellAttributes
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
function M:new()
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
function M:push(background, foreground, text, attributes)
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
function M:draw()
  return self.cells
end

--- Clears all cells from the status bar
---@package
function M:clear()
  self.cells = {}
end

return M
