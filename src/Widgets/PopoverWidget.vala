public class DDCBrightness.Widgets.PopoverWidget : Gtk.Box {
    private Services.DDCService ddc_service;
    private List<DisplayBrightness> brightness_widgets = new List<DisplayBrightness> ();

    public PopoverWidget (Services.DDCService service) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            spacing: 0,
            margin_top: 6,
            margin_bottom: 6,
            margin_start: 6,
            margin_end: 6
        );
        ddc_service = service;

        // 在构造函数中初始化 UI，确保 ddc_service 已设置
        build_ui ();

        ddc_service.displays_changed.connect (() => {
            // 清空并重建 UI
            foreach (var child in get_children ()) {
                remove (child);
            }
            brightness_widgets = new List<DisplayBrightness> ();
            build_ui ();
            show_all ();
        });
    }

    private void build_ui () {
        if (ddc_service == null) {
            var label = new Gtk.Label (_("Service not initialized"));
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            label.sensitive = false;
            add (label);
            return;
        }

        var displays = ddc_service.get_displays ();

        if (displays.length () == 0) {
            var error = ddc_service.get_last_error ();

            var label = new Gtk.Label ("");
            if (error.length > 0) {
                label.label = _("No displays found\n(%s)").printf (error);
            } else {
                label.label = _("No DDC compatible displays detected");
            }
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            label.sensitive = false;
            add (label);
            return;
        }

        bool first = true;
        foreach (var display in displays) {
            if (!first) {
                var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
                    margin_top = 6,
                    margin_bottom = 6
                };
                add (separator);
            }
            first = false;

            var brightness_widget = new DisplayBrightness (ddc_service, display);
            brightness_widgets.append (brightness_widget);
            add (brightness_widget);
        }
    }

    public async void refresh () {
        foreach (var widget in brightness_widgets) {
            yield widget.refresh ();
        }
    }
}
