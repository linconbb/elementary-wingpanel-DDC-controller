#!/bin/bash
# DDC Brightness WingPanel Indicator 安装脚本

set -e

PLUGIN_NAME="libddcbrightness.so"
PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/wingpanel"
SOURCE_DIR="$(dirname "$0")"

echo "=== DDC Brightness WingPanel Indicator 安装 ==="
echo ""

# 检查是否已编译
if [ ! -f "$SOURCE_DIR/build/src/$PLUGIN_NAME" ]; then
    echo "错误：未找到编译好的插件文件"
    echo "请先运行: meson setup build && meson compile -C build"
    exit 1
fi

# 检查依赖
echo "[1/4] 检查依赖..."
if ! command -v ddcutil &> /dev/null; then
    echo "  正在安装 ddcutil..."
    sudo apt update
    sudo apt install -y ddcutil
fi

# 设置 I2C 权限
echo ""
echo "[2/4] 设置 I2C 设备权限..."
if ! groups $USER | grep -q '\bi2c\b'; then
    echo "  将用户 $USER 添加到 i2c 组..."
    sudo usermod -aG i2c $USER
    echo "  ⚠️  需要重新登录才能使权限生效"
fi

# 安装 udev 规则（允许普通用户访问 I2C）
if [ ! -f "/etc/udev/rules.d/45-ddcutil-i2c.rules" ]; then
    echo "  安装 udev 规则..."
    cat << 'EOF' | sudo tee /etc/udev/rules.d/45-ddcutil-i2c.rules > /dev/null
# Grant access to I2C devices for ddcutil
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
EOF
    sudo udevadm control --reload-rules
    sudo udevadm trigger
fi

# 安装插件
echo ""
echo "[3/4] 安装插件..."
sudo cp "$SOURCE_DIR/build/src/$PLUGIN_NAME" "$PLUGIN_DIR/"
sudo chmod 644 "$PLUGIN_DIR/$PLUGIN_NAME"
echo "  已安装到: $PLUGIN_DIR/$PLUGIN_NAME"

# 重启 WingPanel
echo ""
echo "[4/4] 重启 WingPanel..."
killall wingpanel 2>/dev/null || true
sleep 1

# 检查 WingPanel 是否自动重启
if ! pgrep -x "wingpanel" > /dev/null; then
    echo "  正在启动 WingPanel..."
    wingpanel &
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "如果未看到亮度图标，请检查:"
echo "1. 显示器是否支持 DDC/CI 并已启用"
echo "2. 运行 'ddcutil detect' 是否能检测到显示器"
echo "3. 重新登录以使 I2C 权限生效"
echo ""
echo "手动测试命令:"
echo "  ddcutil detect          # 检测显示器"
echo "  ddcutil getvcp 10       # 获取当前亮度"
echo "  ddcutil setvcp 10 50    # 设置亮度为 50%"
