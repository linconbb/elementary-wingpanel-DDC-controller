#!/bin/bash
# DDC Brightness WingPanel Indicator Uninstallation Script

PLUGIN_NAME="libddcbrightness.so"
PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/wingpanel"

echo "=== DDC Brightness WingPanel Indicator Uninstallation ==="
echo ""

# Remove plugin
if [ -f "$PLUGIN_DIR/$PLUGIN_NAME" ]; then
    echo "[1/2] Removing plugin..."
    sudo rm "$PLUGIN_DIR/$PLUGIN_NAME"
    echo "  Removed: $PLUGIN_DIR/$PLUGIN_NAME"
else
    echo "  Plugin not installed"
fi

# Restart WingPanel
echo ""
echo "[2/2] Restarting WingPanel..."
killall wingpanel 2>/dev/null || true
sleep 1

if ! pgrep -x "wingpanel" > /dev/null; then
    wingpanel &
fi

echo ""
echo "=== Uninstallation Complete ==="
echo ""
echo "Optional: Remove udev rules (if no longer needed for ddcutil)"
echo "  sudo rm /etc/udev/rules.d/45-ddcutil-i2c.rules"
