# DDC Brightness WingPanel Indicator

A WingPanel indicator for elementary OS that allows controlling external monitor brightness via DDC/CI protocol.

## Features

- Detect DDC/CI compatible displays automatically
- Adjust brightness via slider in the popover
- Scroll on the indicator icon to quickly adjust brightness
- Support for multiple displays
- Auto-refresh display list (handles hot-plugging)
- Real-time brightness reading from display

## Requirements

- elementary OS 8.x (or later)
- ddcutil
- libwingpanel-dev
- libgranite-7-dev

## Installation

### Option 1: One-Click Install (Recommended)

If you have the pre-built binary:

```bash
./install.sh
```

This will automatically:
1. Install ddcutil if not present
2. Set up I2C permissions
3. Install the plugin to WingPanel directory
4. Restart WingPanel

Then log out and log back in for I2C group changes to take effect.

### Option 2: Build from Source

#### Install Dependencies

```bash
sudo apt install ddcutil libwingpanel-dev libgranite-7-dev valac meson
```

#### Setup I2C Permissions

To use ddcutil without sudo:

```bash
sudo usermod -aG i2c $USER
# Log out and log back in for group changes to take effect
```

#### Build and Install

```bash
meson setup build --prefix=/usr
meson compile -C build
sudo meson install -C build
```

#### Restart WingPanel

```bash
killall io.elementary.wingpanel
```

The indicator should appear automatically in the top panel when DDC-compatible displays are detected.

## Uninstallation

```bash
./uninstall.sh
```

Or manually:

```bash
sudo rm /usr/lib/x86_64-linux-gnu/wingpanel/libddcbrightness.so
killall io.elementary.wingpanel
```

## Usage

- **Click** the brightness icon in the top panel to open the control popover
- **Drag** the slider to adjust brightness
- **Scroll** on the icon to quickly adjust brightness (±5% per scroll)

## Troubleshooting

### Indicator not showing

Check if your display supports DDC/CI:

```bash
ddcutil detect
```

If no displays are found, check that:
1. Your monitor supports DDC/CI (check monitor OSD settings)
2. You're using a compatible connection (DP, HDMI, USB-C with DP alt mode)
3. You have I2C permissions (member of `i2c` group)

### Brightness shows 0%

This usually means the display doesn't support brightness control via DDC/CI, or the VCP code is different.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     WingPanel Top Bar                        │
│  ┌─────────────┐                                             │
│  │ Brightness  │ ← DisplayWidget (icon + scroll handler)     │
│  │   Icon      │                                             │
│  └──────┬──────┘                                             │
└─────────┼─────────────────────────────────────────────────────┘
          │ click
          ▼
┌─────────────────────────────────────────────────────────────┐
│                      PopoverWidget                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Display Name                                  50%      │ │
│  │  [◯───────────────────────────────────────────◯]      │ │
│  │  Dim ▲                                    Bright ▲     │ │
│  └─────────────────────────────────────────────────────────┘ │
│  ───────────────────────────────────────────────────────────│
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ Display 2                                   75%        │ │
│  │  [◯────────────────────────◯─────────────────────────◯] │ │
│  │  Dim ▲                                    Bright ▲     │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

Services:
- DDCService: Wraps ddcutil commands, manages display list
- Display: Data model for a single display
```

## File Structure

```
.
├── meson.build              # Root build file
├── README.md                # This file
├── install.sh               # One-click install script
├── uninstall.sh             # Uninstall script
├── data/
│   ├── meson.build
│   └── ddcbrightness.desktop
├── po/
│   └── meson.build          # Translations
└── src/
    ├── meson.build          # Source build file
    ├── config.vala.in       # Build configuration template
    ├── Indicator.vala       # Main Wingpanel.Indicator subclass
    ├── Services/
    │   ├── DDCService.vala  # ddcutil wrapper
    │   └── Display.vala     # Display data model
    └── Widgets/
        ├── DisplayWidget.vala      # Top bar icon
        ├── PopoverWidget.vala      # Popover container
        └── DisplayBrightness.vala  # Brightness slider for one display
```

## DDC/CI VCP Codes

- `0x10` (16): Brightness - Used by this indicator
- `0x12` (18): Contrast - Not implemented (potential future feature)

## Technical Details

- Built with Vala and GTK3
- Uses ddcutil command-line tool for DDC/CI communication
- Debounced slider (300ms) for smooth UX
- Async operations to prevent UI blocking

## License

GPL-3.0+
