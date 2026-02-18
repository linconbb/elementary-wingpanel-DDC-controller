#!/bin/bash
# DDC Brightness WingPanel Indicator 卸载脚本

PLUGIN_NAME="libddcbrightness.so"
PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/wingpanel"

echo "=== DDC Brightness WingPanel Indicator 卸载 ==="
echo ""

# 删除插件
if [ -f "$PLUGIN_DIR/$PLUGIN_NAME" ]; then
    echo "[1/2] 删除插件..."
    sudo rm "$PLUGIN_DIR/$PLUGIN_NAME"
    echo "  已删除: $PLUGIN_DIR/$PLUGIN_NAME"
else
    echo "  插件未安装"
fi

# 重启 WingPanel
echo ""
echo "[2/2] 重启 WingPanel..."
killall wingpanel 2>/dev/null || true
sleep 1

if ! pgrep -x "wingpanel" > /dev/null; then
    wingpanel &
fi

echo ""
echo "=== 卸载完成 ==="
echo ""
echo "可选：删除 udev 规则（如果不再需要 ddcutil）"
echo "  sudo rm /etc/udev/rules.d/45-ddcutil-i2c.rules"
