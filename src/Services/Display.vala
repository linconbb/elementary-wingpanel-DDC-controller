public class DDCBrightness.Services.Display : Object {
    public int display_number { get; set; }
    public string i2c_bus { get; set; }
    public string name { get; set; }
    public int brightness { get; set; }

    public Display () {
        display_number = 0;
        i2c_bus = "";
        name = _("Unknown Display");
        brightness = 50;
    }

    public string get_display_name () {
        if (name != null && name.length > 0) {
            return name;
        }
        return _("Display %d").printf (display_number);
    }
}
