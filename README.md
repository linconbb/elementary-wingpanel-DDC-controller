# DDC Brightness WingPanel Indicator

A WingPanel indicator for elementary OS that allows controlling external monitor brightness via DDC/CI protocol.

## Features

- Detect DDC/CI compatible displays automatically
- Adjust brightness via slider in the popover
- Scroll on the indicator icon to quickly adjust brightness
- Support for multiple displays
- Auto-refresh display list (handles hot-plugging)

## Requirements

- elementary OS 8.x (or later)
- ddcutil
- libwingpanel-dev
- libgranite-7-dev
- valac
- meson

## Installation

### Install Dependencies

```bash
sudo apt install ddcutil libwingpanel-dev libgranite-7-dev valac meson
```

### Setup udev Rules (for non-root access)

To use ddcutil without sudo, add udev rules:

```bash
sudo usermod -aG i2c $USER
# Log out and log back in for group changes to take effect
```

### Build and Install

```bash
meson setup build --prefix=/usr
meson compile -C build
sudo meson install -C build
```

### Restart WingPanel

```bash
killall wingpanel
```

The indicator should appear automatically in the top panel when DDC-compatible displays are detected.

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

## License

GPL-3.0+
