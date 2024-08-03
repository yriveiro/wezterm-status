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

This project works with the native plugin system provided by WezTerm.

Modify your WezTerm configuration file (~/.config/wezterm/wezterm.lua) to include
the status bar script:

```lua

    local wezterm = require 'wezterm'
    local config = wezterm.config_builder()

    ...

    wezterm.plugin
      .require('https://github.com/yriveiro/wezterm-status')
      .apply_to_config(config)
```

# Setup

Once configured, the status bar will automatically update with the relevant
information when WezTerm is running. You can modify the configuration to
suit your needs, enabling or disabling different cells as required.

To customize the plugin, the method `apply_to_config` accepts a second argument
for the plugin options.

In this example, we are configuring the format date applied.

```lua

    local wezterm = require 'wezterm'
    local config = wezterm.config_builder()

    ...

    wezterm.plugin
      .require('https://github.com/yriveiro/wezterm-status')
      .apply_to_config(config, { cells = { date = {
        format = '%H:%M',
      } } })```

# Available configurations

- *mode*: Configures the mode indicator.
- *battery*: Enables or disables the battery status.
- *hostname*: Enables or disables the hostname cell.
- *cwd*: Enables or disables the current working directory cell.
- *date*: Configures the date/time cell, including format.

The current defaults are:

```lua

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
    },
    date = {
      enabled = true,
      icon = wezterm.nerdfonts.md_clock_time_three_outline,
      format = '%Y-%m-%d %H:%M:%S',
    },
  },
}
```

# Usage

Once configured, the status bar will automatically update with the relevant
information when WezTerm is running. You can modify the configuration to
suit your needs, enabling or disabling different cells as required.

# Contributing

Contributions are welcome! Please open an issue or submit a pull request with your improvements.

# License

This project is licensed under the MIT License. See the LICENSE file for details.
