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
---@field custom? fun(): string Custom callback that will allow to format the battery

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
---@field private cells? table Storage for the cells
---@field protected attrs? WeztermStatusCellAttributes Available text formatting attributes
---@field new fun(self: WeztermStatusCells): WeztermStatusCells Creates a new Cells instance
---@field push fun(self: WeztermStatusCells, background: string, foreground: string, text: string, attributes: string[]?): nil Adds a new cell with specified styling
---@field draw fun(self: WeztermStatusCells): FormatItem[] Returns formatted items for rendering
---@field clear fun(self: WeztermStatusCells): nil Clears all cells

---@class CWD
---@field file_path string current path
---@field host string Name of the host
