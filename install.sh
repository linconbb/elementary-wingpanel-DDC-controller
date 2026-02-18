#!/bin/bash
# DDC Brightness WingPanel Indicator Installation Script

set -e

PLUGIN_NAME="libddcbrightness.so"
PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/wingpanel"
SOURCE_DIR="$(dirname "$0")"

echo "=== DDC Brightness WingPanel Indicator Installation ==="
echo ""

# Check if compiled
if [ ! -f "$SOURCE_DIR/build/src/$PLUGIN_NAME" ]; then
    echo "Error: Compiled plugin file not found"
    echo "Please run: meson setup build && meson compile -C build"
    exit 1
fi

# Check dependencies
echo "[1/4] Checking dependencies..."
if ! command -v ddcutil &> /dev/null; then
    echo "  Installing ddcutil..."
    sudo apt update
    sudo apt install -y ddcutil
fi

# Setup I2C permissions
echo ""
echo "[2/4] Setting up I2C device permissions..."
if ! groups $USER | grep -q '\bi2c\b'; then
    echo "  Adding user $USER to i2c group..."
    sudo usermod -aG i2c $USER
    echo "  ⚠️  Please log out and log back in for permissions to take effect"
fi

# Install udev rules (allow regular users to access I2C)
if [ ! -f "/etc/udev/rules.d/45-ddcutil-i2c.rules" ]; then
    echo "  Installing udev rules..."
    cat << 'EOF' | sudo tee /etc/udev/rules.d/45-ddcutil-i2c.rules > /dev/null
# Grant access to I2C devices for ddcutil
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
fi

# Install plugin
echo ""
echo "[3/4] Installing plugin..."
sudo cp "$SOURCE_DIR/build/src/$PLUGIN_NAME" "$PLUGIN_DIR/"
sudo chmod 644 "$PLUGIN_DIR/$PLUGIN_NAME"
echo "  Installed to: $PLUGIN_DIR/$PLUGIN_NAME"

# Restart WingPanel
echo ""
echo "[4/4] Restarting WingPanel..."
killall wingpanel 2>/dev/null || true
sleep 1

# Check if WingPanel auto-restarted
if ! pgrep -x "wingpanel" > /dev/null; then
    echo "  Starting WingPanel..."
    wingpanel &
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "If the brightness icon is not visible, please check:"
echo "1. Whether your display supports DDC/CI and has it enabled"
echo "2. Run 'ddcutil detect' to see if displays are detected"
echo "3. Log out and log back in for I2C permissions to take effect"
echo ""
echo "Manual test commands:"
echo "  ddcutil detect          # Detect displays"
echo "  ddcutil getvcp 10       # Get current brightness"
echo "  ddcutil setvcp 10 50    # Set brightness to 50%"
