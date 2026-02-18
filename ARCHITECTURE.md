# DDC Brightness WingPanel Indicator - 架构设计

## 概述

这是一个为 elementary OS Pantheon 桌面环境开发的 WingPanel 顶部栏插件，用于通过 DDC/CI 协议控制外接显示器的亮度。

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              WingPanel                                       │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                          DDCBrightness.Indicator                       │  │
│  │  ┌─────────────────┐                    ┌──────────────────────────┐  │  │
│  │  │ DisplayWidget   │ ←──点击/滚动────→  │ PopoverWidget            │  │  │
│  │  │ (Gtk.EventBox)  │                    │ (Gtk.Box)                │  │  │
│  │  │                 │                    │                          │  │  │
│  │  │ ┌─────────────┐ │                    │ ┌──────────────────────┐ │  │  │
│  │  │ │ 亮度图标    │ │                    │ │ DisplayBrightness    │ │  │  │
│  │  │ │ (随亮度变化)│ │                    │ │ (亮度滑块控件)        │ │  │  │
│  │  │ └─────────────┘ │                    │ │  - 名称标签           │ │  │  │
│  │  └─────────────────┘                    │ │  - 亮度滑块 (0-100)   │ │  │  │
│  │                                          │ │  - 数值标签           │ │  │  │
│  │           ┌───────────────────────────┐  │ └──────────────────────┘ │  │  │
│  │           │    DDCService (单例)      │  │                          │  │  │
│  │           │                           │  │ ┌──────────────────────┐ │  │  │
│  └──────────→│  - 显示器检测              │←────────────────────────────┘  │  │
│             │  - 亮度读取/设置            │         (多个显示器支持)       │  │
│             │  - 信号通知                 │                                │  │
│             │                           │                                │  │
│             │  ┌─────────────────────┐  │                                │  │
│             └──┤ Display (数据模型)   ├──┘                                │  │
│                │ - display_number    │                                   │  │
│                │ - i2c_bus           │                                   │  │
│                │ - name              │                                   │  │
│                │ - brightness        │                                   │  │
│                └─────────────────────┘                                   │  │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │    ddcutil    │
                              │   (命令行)    │
                              └───────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │   I2C Bus     │
                              │  /dev/i2c-N   │
                              └───────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │  DDC/CI 显示器 │
                              │   VCP 0x10    │
                              └───────────────┘
```

## 组件详细说明

### 1. Indicator (`src/Indicator.vala`)

WingPanel 插件的主入口点，继承自 `Wingpanel.Indicator`。

**职责：**
- 初始化 i18n 和 DDCService
- 管理顶部栏显示控件 (`DisplayWidget`)
- 管理弹出面板 (`PopoverWidget`)
- 处理插件生命周期（打开/关闭）
- 根据显示器可用性控制可见性

**关键方法：**
- `get_display_widget()`: 返回顶部栏显示的图标控件
- `get_widget()`: 返回点击后弹出的面板控件
- `opened()/closed()`: 面板打开/关闭时的回调

### 2. DisplayWidget (`src/Widgets/DisplayWidget.vala`)

顶部栏显示的亮度图标，继承自 `Gtk.EventBox`。

**职责：**
- 显示当前亮度对应的图标（暗/中/亮）
- 处理滚轮事件快速调节亮度
- 响应亮度变化信号更新图标

**交互：**
- 滚轮向上：增加亮度 (+5%)
- 滚轮向下：减少亮度 (-5%)

### 3. PopoverWidget (`src/Widgets/PopoverWidget.vala`)

点击图标后弹出的控制面板，继承自 `Gtk.Box`。

**职责：**
- 容器，管理一个或多个 `DisplayBrightness` 控件
- 响应显示器列表变化（热插拔）重建 UI
- 协调多个显示器的亮度控制

### 4. DisplayBrightness (`src/Widgets/DisplayBrightness.vala`)

单个显示器的亮度控制组件，包含滑块和数值显示。

**职责：**
- 显示显示器名称和当前亮度百分比
- 提供 0-100 的亮度滑块
- 实时同步亮度变化（来自滑块、滚轮或其他控制）

**UI 组件：**
- 名称标签（左侧，截断显示）
- 亮度值标签（右侧，百分比）
- 滑块（带 25/50/75 标记）
- 暗/亮图标提示

### 5. DDCService (`src/Services/DDCService.vala`)

单例服务，封装 ddcutil 命令行工具的所有操作。

**职责：**
- 检测 DDC/CI 兼容显示器
- 读取和设置显示器亮度
- 管理显示器列表，处理热插拔
- 发出信号通知 UI 更新

**信号：**
- `displays_changed`: 显示器列表发生变化
- `brightness_changed`: 某个显示器亮度发生变化

**ddcutil 命令：**
```bash
# 检测显示器
ddcutil detect --brief

# 获取亮度 (VCP 0x10)
ddcutil getvcp 10 --display N --brief

# 设置亮度
ddcutil setvcp 10 <value> --display N
```

### 6. Display (`src/Services/Display.vala`)

显示器数据模型。

**属性：**
- `display_number`: ddcutil 分配的显示器编号
- `i2c_bus`: I2C 总线路径 (如 /dev/i2c-11)
- `name`: 显示器名称（从 EDID 解析）
- `brightness`: 当前亮度值（缓存）

## 数据流

### 初始化流程
```
Indicator.construct()
    └── DDCService.get_default()
        └── detect_displays() ──→ ddcutil detect
            └── 发现显示器列表
                └── displays_changed 信号
                    └── Indicator.update_visibility()
                        └── 设置 visible = true
```

### 用户调节亮度流程
```
用户拖动滑块
    └── DisplayBrightness.value_changed
        └── DDCService.set_brightness()
            └── ddcutil setvcp 10 <value>
                └── 成功 → display.brightness = value
                    └── brightness_changed 信号
                        ├── DisplayBrightness.update_scale_value() (同步滑块)
                        └── DisplayWidget.update_icon() (同步图标)
```

### 滚轮快速调节流程
```
用户在图标上滚轮
    └── DisplayWidget.scroll_event
        └── DDCService.set_brightness()
            └── (同上)
```

## 技术要点

### DDC/CI VCP 代码
- **0x10 (16)**: 亮度 (Brightness) - 本插件使用的特性
- ddcutil 使用十进制或十六进制（带 0x 前缀）

### GTK3 vs GTK4
本项目使用 GTK3，因为 elementary OS 8 的 WingPanel 3.0 基于 GTK3。

**主要差异处理：**
- 使用 `Gtk.EventBox` + `scroll_event` 信号而非 `EventControllerScroll`
- 使用 `pack_start/pack_end` 而非 `append`
- 使用 `get_style_context().add_class` 而非 `add_css_class`
- 使用 `foreach (var child in get_children())` 遍历子元素

### 异步处理
所有 ddcutil 调用都是异步的（`async/await`），避免阻塞 UI：
- `detect_displays()`: 可能耗时数秒
- `get_brightness()`: 需要等待 I2C 通信
- `set_brightness()`: 需要等待显示器响应

### 权限要求
ddcutil 需要访问 `/dev/i2c-*` 设备。安装方式：
1. 将用户加入 `i2c` 组: `sudo usermod -aG i2c $USER`
2. 或使用 udev 规则设置设备权限

## 文件结构

```
.
├── meson.build                 # 根构建文件
├── data/
│   ├── meson.build
│   └── ddcbrightness.desktop   # 桌面文件（用于应用菜单）
├── po/
│   └── meson.build             # 国际化（翻译）
└── src/
    ├── meson.build             # 源文件构建配置
    ├── config.vala.in          # 构建时配置模板
    ├── Indicator.vala          # 插件主类
    ├── Services/
    │   ├── DDCService.vala     # ddcutil 封装服务
    │   └── Display.vala        # 显示器数据模型
    └── Widgets/
        ├── DisplayWidget.vala      # 顶部栏图标
        ├── PopoverWidget.vala      # 弹出面板容器
        └── DisplayBrightness.vala  # 亮度滑块控件
```

## 扩展性考虑

### 多显示器支持
- `DDCService` 管理 `List<Display>`
- `PopoverWidget` 为每个显示器创建一个 `DisplayBrightness`
- 显示器之间用分隔线区分

### 未来可能的扩展
1. **对比度控制**: VCP 0x12，类似亮度添加滑块
2. **输入源切换**: VCP 0x60，添加下拉菜单
3. **显示预设**: 保存/加载亮度配置
4. **自动亮度**: 根据环境光传感器调节

## 调试

启用调试输出：
```bash
G_MESSAGES_DEBUG=io.elementary.wingpanel.ddcbrightness wingpanel
```

手动测试 ddcutil：
```bash
# 检测显示器
ddcutil detect

# 获取亮度
ddcutil getvcp 10 --brief

# 设置亮度为 50%
ddcutil setvcp 10 50
```
