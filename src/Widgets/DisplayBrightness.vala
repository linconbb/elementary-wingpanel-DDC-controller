public class DDCBrightness.Widgets.DisplayBrightness : Gtk.Box {
    private Services.DDCService ddc_service;
    private Services.Display display;
    private Gtk.Scale brightness_scale;
    private Gtk.Label value_label;
    private bool updating = false;
    private uint debounce_timeout_id = 0;
    private int pending_brightness = -1;
    private bool is_dragging = false;

    public DisplayBrightness (Services.DDCService service, Services.Display disp) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 6
        );
        ddc_service = service;
        display = disp;
        margin_top = 6;
        margin_bottom = 6;
        margin_start = 6;
        margin_end = 6;

        build_ui ();
    }

    private void build_ui () {
        // 显示器名称标签
        var name_label = new Gtk.Label (display.get_display_name ()) {
            halign = Gtk.Align.START,
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            max_width_chars = 30
        };
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        // 亮度值标签
        value_label = new Gtk.Label ("%d%%".printf (display.brightness)) {
            halign = Gtk.Align.END
        };
        value_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        header_box.pack_start (name_label, false, false, 0);
        header_box.pack_end (value_label, false, false, 0);

        // 亮度滑块
        var adjustment = new Gtk.Adjustment (display.brightness, 0, 100, 1, 5, 0);
        brightness_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, adjustment) {
            draw_value = false,
            hexpand = true
        };
        brightness_scale.add_mark (25, Gtk.PositionType.TOP, null);
        brightness_scale.add_mark (50, Gtk.PositionType.TOP, null);
        brightness_scale.add_mark (75, Gtk.PositionType.TOP, null);

        // 使用相同的图标避免问号问题
        var min_icon = new Gtk.Image.from_icon_name ("display-brightness-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        min_icon.set_tooltip_text (_("Dim"));

        var max_icon = new Gtk.Image.from_icon_name ("display-brightness-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        max_icon.set_tooltip_text (_("Bright"));

        var scale_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        scale_box.pack_start (min_icon, false, false, 0);
        scale_box.pack_start (brightness_scale, true, true, 0);
        scale_box.pack_start (max_icon, false, false, 0);

        pack_start (header_box, false, false, 0);
        pack_start (scale_box, false, true, 0);

        // 检测鼠标按下/释放，优化拖动体验
        brightness_scale.add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);

        brightness_scale.button_press_event.connect ((event) => {
            is_dragging = true;
            return false;
        });

        brightness_scale.button_release_event.connect ((event) => {
            is_dragging = false;
            // 释放时立即执行
            if (pending_brightness >= 0) {
                if (debounce_timeout_id > 0) {
                    Source.remove (debounce_timeout_id);
                    debounce_timeout_id = 0;
                }
                execute_brightness_change (pending_brightness);
                pending_brightness = -1;
            }
            return false;
        });

        // 滑块值改变时更新 UI
        brightness_scale.value_changed.connect (() => {
            if (!updating) {
                int new_value = (int) brightness_scale.get_value ();
                value_label.label = "%d%%".printf (new_value);
                pending_brightness = new_value;

                // 只在非拖动状态下使用短延迟
                if (!is_dragging) {
                    if (debounce_timeout_id > 0) {
                        Source.remove (debounce_timeout_id);
                    }
                    debounce_timeout_id = Timeout.add (100, () => {
                        if (pending_brightness >= 0) {
                            execute_brightness_change (pending_brightness);
                            pending_brightness = -1;
                        }
                        debounce_timeout_id = 0;
                        return false;
                    });
                }
            }
        });

        // 监听亮度变化（来自滚轮或其他控制）
        ddc_service.brightness_changed.connect ((changed_display) => {
            if (changed_display.display_number == display.display_number) {
                update_scale_value (changed_display.brightness);
            }
        });
    }

    private void execute_brightness_change (int value) {
        // 在后台线程执行，避免阻塞 UI
        new Thread<void> ("brightness-set", () => {
            ddc_service.set_brightness.begin (display, value);
        });
    }

    private void update_scale_value (int value) {
        updating = true;
        brightness_scale.set_value (value);
        value_label.label = "%d%%".printf (value);
        updating = false;
    }

    public async void refresh () {
        // 重新读取当前亮度并更新显示
        int brightness = yield ddc_service.get_brightness (display);
        if (brightness >= 0) {
            display.brightness = brightness;
            update_scale_value (brightness);
        } else {
            // 如果无法读取亮度，禁用控件
            brightness_scale.sensitive = false;
            value_label.label = _("N/A");
        }
    }
}
