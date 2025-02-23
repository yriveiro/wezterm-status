# WezTerm Status

This project provides a configurable status bar for [WezTerm](https://wezfurlong.org/wezterm/index.html),
a GPU-accelerated terminal emulator. It includes various features like battery
status, current mode, hostname, current working directory, and date/time, all
displayed in a customizable status bar.

# Features

- Mode Indicator: Shows the current mode (normal, copy, search) with icons.
- Battery Status: Displays the battery level with appropriate icons.
- Hostname: Displays the hostname of the current machine.
- Current Working Directory: Shows the current working directory.
- Date/Time: Displays the current date and time in a customizable format.

# Installation

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-status')
  .apply_to_config(config)
```

# Setup

Customize the plugin with the `apply_to_config` method's second argument:

```lua
wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-status')
  .apply_to_config(config, {
    cells = {
      battery = { enabled = false },
      date = { format = '%H:%M' }
    }
  })
```

# Available configurations

## UI Section

Controls visual elements and separators.

### Theme

The plugin will try to use wezterm.config.colors.tab_bar if it's defined, if
if it's not, will try config.ui.theme defined the plugin, in case none of both
are defined, will use a fallback theme.

> [!NOTE]
> The plugin will first try to use wezterm.config.colors.tab_bar if it is defined.
> If not, it will check config.ui.theme from the plugin's configuration. If neither
> is set, it will fall back to a default theme.

```lua
ui.theme = {
  bg_color = '#88C0D0',
  fg_color = '#2E3440',
  intensity = 'Normal',
  underline = 'None',
  italic = false,
  strikethrough = false,
}
```

### Separators

```lua
ui.separators = {
  -- Powerline-style arrows
  arrow_solid_left = '\u{e0b0}',
  arrow_solid_right = '\u{e0b2}',
  arrow_thin_left = '\u{e0b1}',
  arrow_thin_right = '\u{e0b3}',
}
```

## Cells Section

### Mode Indicator

```lua
cells.mode = {
  -- Enable mode display
  enabled = true,
  -- Map modes to icons
  modes = {
    normal = ' ' .. wezterm.nerdfonts.cod_home,
    copy_mode = ' ' .. wezterm.nerdfonts.cod_copy,
    search_mode = ' ' .. wezterm.nerdfonts.cod_search,
  }
}
```

### Battery Indicator

```lua
cells.battery = {
  -- Enable battery status
  enabled = true
}
```

Shows dynamic icons based on charge level:

- Empty: ≤ 25%
- Quarter: ≤ 50%
- Three Quarters: ≤ 75%
- Full: > 75%

### Hostname Display

```lua
cells.hostname = {
  -- Enable hostname
  enabled = true
}
```

### Current Working Directory

```lua
cells.cwd = {
  -- Enable CWD display
  enabled = true,
  -- Replace $HOME with ~
  tilde_prefix = true,
  -- Path aliases for shortening
  path_aliases = {
    -- Replace long development path with an icon
    { pattern = "/home/user/development", replacement = "🛠️" },
    -- Use git icon for repositories
    { pattern = "/home/user/repos", replacement = "" },
    -- Docker projects
    { pattern = "/home/user/docker", replacement = "🐳" },
    -- Kubernetes configuration
    { pattern = "/home/user/.kube", replacement = "☸️" }
  }
}
```

The status bar supports path aliases to create more compact and readable directory
paths. This feature is particularly useful for frequently accessed directories or
deep nested paths.

With this configuration path will be aliased to

```sh
/home/user/development/project → 🛠️/project
/home/user/repos/my-app → /my-app
/home/user/docker/compose → 🐳/compose
```

This feature helps maintain a clean status bar while preserving path context through
meaningful icons or abbreviations.

### Wezterm Workspace

```lua
cells.workspace = {
  -- Enable Wezterm Workspace
  enabled = true,
  -- Clock icon
  icon = wezterm.nerdfonts.md_television_guide,
}
```

### Date/Time Display

```lua
cells.date = {
  -- Enable timestamp
  enabled = true,
  -- Clock icon
  icon = wezterm.nerdfonts.md_clock_time_three_outline,
  -- Time format (strftime)
  format = '%H:%M:%S'
}
```

### Kubernetes Current Context

The component will try to guess the path but the process is prone to error, if
the current logic doesn't find the binary you can pass it on `kubectl_path`

```lua
cells.k8s_context = {
  enabled = true,
  -- If the current autodiscovery logic doesn't work add kubectl_path
  kubectl_path = '/usr/local/bin/kubectl'
}
```

# Cell Formatting

Available text attributes:

- `Bold`: Bold intensity
- `Curly`/`Dashed`/`Dotted`/`Double`/`Single`: Underline styles
- `Half`: Half intensity
- `Italic`/`NoItalic`: Italic control
- `NoUnderline`: Remove underline
- `Normal`: Normal intensity

# Contributing

Open issues or submit pull requests with improvements.

# License

MIT License
