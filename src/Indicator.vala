public class DDCBrightness.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "display-brightness-symbolic";

    private Widgets.DisplayWidget? display_widget = null;
    private Widgets.PopoverWidget? popover_widget = null;
    private Services.DDCService ddc_service;

    public Indicator () {
        Object (
            code_name: "ddcbrightness"
        );
    }

    construct {
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");

        ddc_service = Services.DDCService.get_default ();
        ddc_service.displays_changed.connect (update_visibility);

        // 默认显示指示器，即使检测失败
        // DDCService 会在初始化后自动检测
        visible = true;
    }

    public override Gtk.Widget get_display_widget () {
        if (display_widget == null) {
            display_widget = new Widgets.DisplayWidget (ddc_service);

            // GTK3: 使用 scroll-event 信号
            display_widget.scroll_event.connect ((event) => {
                if (popover_widget == null || !popover_widget.get_visible ()) {
                    var display = ddc_service.get_primary_display ();
                    if (display != null) {
                        int delta = (event.direction == Gdk.ScrollDirection.DOWN) ? -5 : 5;
                        if (event.direction == Gdk.ScrollDirection.SMOOTH) {
                            delta = (event.delta_y > 0) ? -5 : 5;
                        }
                        int new_brightness = (int) (display.brightness + delta);
                        new_brightness = new_brightness.clamp (0, 100);
                        ddc_service.set_brightness.begin (display, new_brightness);
                    }
                }
                return true;
            });
        }

        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        if (popover_widget == null) {
            popover_widget = new Widgets.PopoverWidget (ddc_service);
        }

        return popover_widget;
    }

    public override void opened () {
        // 弹出面板打开时刷新亮度值
        if (popover_widget != null) {
            popover_widget.refresh.begin ();
        }
    }

    public override void closed () {
    }

    private void update_visibility () {
        bool has_displays = ddc_service.get_display_count () > 0;
        if (visible != has_displays) {
            visible = has_displays;
        }

        if (display_widget != null) {
            display_widget.update_icon ();
        }
    }
}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    var indicator = new DDCBrightness.Indicator ();
    return indicator;
}

public void module_load (Module module) {
}

public void module_unload (Module module) {
}
