public class DDCBrightness.Widgets.DisplayWidget : Gtk.EventBox {
    private Services.DDCService ddc_service;
    private Gtk.Image icon;

    public DisplayWidget (Services.DDCService service) {
        Object ();
        ddc_service = service;
    }

    construct {
        icon = new Gtk.Image.from_icon_name ("display-brightness-symbolic", Gtk.IconSize.MENU);
        icon.set_pixel_size (24);
        icon.set_tooltip_text (_("External Display Brightness"));

        add (icon);

        ddc_service.brightness_changed.connect (() => {
            update_icon ();
        });

        // GTK3 使用 scroll-event 信号
        add_events (Gdk.EventMask.SCROLL_MASK);
    }

    public void update_icon () {
        // 始终使用同一个图标，避免图标不存在的问题
        // 只更新 tooltip 显示当前亮度
        var display = ddc_service.get_primary_display ();
        if (display != null) {
            icon.set_tooltip_text (_("Brightness: %d%%").printf (display.brightness));
        }
    }
}
