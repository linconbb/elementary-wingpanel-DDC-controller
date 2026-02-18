public class DDCBrightness.Services.DDCService : Object {
    private static DDCService? instance = null;

    private List<Display> _displays = new List<Display> ();
    private uint refresh_timeout_id = 0;
    private string last_error = "";

    public signal void displays_changed ();
    public signal void brightness_changed (Display display);

    public static DDCService get_default () {
        if (instance == null) {
            instance = new DDCService ();
        }
        return instance;
    }

    private DDCService () {
        // 立即检测一次（不延迟）
        detect_displays.begin ();

        // 定期刷新显示器列表（处理热插拔）
        refresh_timeout_id = Timeout.add_seconds (10, () => {
            detect_displays.begin ();
            return Source.CONTINUE;
        });
    }

    ~DDCService () {
        if (refresh_timeout_id > 0) {
            Source.remove (refresh_timeout_id);
        }
    }

    public string get_last_error () {
        return last_error;
    }

    public List<Display> get_displays () {
        var result = new List<Display> ();
        foreach (var display in _displays) {
            result.append (display);
        }
        return result;
    }

    public uint get_display_count () {
        return _displays.length ();
    }

    public Display? get_primary_display () {
        if (_displays.length () > 0) {
            return _displays.nth_data (0);
        }
        return null;
    }

    public async void detect_displays () {
        last_error = "";

        var new_displays = do_detect ();

        // 检查是否有变化
        bool changed = false;
        if (new_displays.length () != _displays.length ()) {
            changed = true;
        } else {
            for (uint i = 0; i < new_displays.length (); i++) {
                var new_disp = new_displays.nth_data (i);
                var old_disp = _displays.nth_data (i);
                if (new_disp.i2c_bus != old_disp.i2c_bus) {
                    changed = true;
                    break;
                }
            }
        }

        if (changed) {
            _displays = null;
            foreach (var display in new_displays) {
                _displays.append (display);
            }
            // 获取每个显示器的初始亮度
            foreach (var display in _displays) {
                yield refresh_brightness (display);
            }
            displays_changed ();
        }
    }

    private List<Display> do_detect () {
        var displays = new List<Display> ();

        try {
            string[] spawn_args = {"/usr/bin/ddcutil", "detect", "--brief"};
            string stdout_str;
            string stderr_str;
            int exit_status;

            Process.spawn_sync (
                ".",
                spawn_args,
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout_str,
                out stderr_str,
                out exit_status
            );

            if (exit_status != 0) {
                last_error = "ddcutil failed (exit %d)".printf (exit_status);
                return displays;
            }

            // 解析输出
            var lines = stdout_str.split ("\n");
            Display? current_display = null;

            foreach (var line in lines) {
                var trimmed = line.strip ();
                if (trimmed.length == 0) continue;

                if (trimmed.has_prefix ("Display ")) {
                    current_display = new Display ();
                    var parts = trimmed.split (" ");
                    if (parts.length >= 2) {
                        current_display.display_number = int.parse (parts[1]);
                    }
                } else if (trimmed.has_prefix ("I2C bus:")) {
                    if (current_display != null) {
                        var parts = trimmed.split (":", 2);
                        if (parts.length >= 2) {
                            current_display.i2c_bus = parts[1].strip ();
                        }
                    }
                } else if (trimmed.has_prefix ("Monitor:")) {
                    if (current_display != null) {
                        var parts = trimmed.split (":", 2);
                        if (parts.length >= 2) {
                            current_display.name = parts[1].strip ();
                        }
                        displays.append (current_display);
                        current_display = null;
                    }
                }
            }

        } catch (Error e) {
            last_error = "Exception: %s".printf (e.message);
        }

        return displays;
    }

    public async int get_brightness (Display display) {
        try {
            string[] spawn_args = {
                "/usr/bin/ddcutil", "getvcp", "10",
                "--display", display.display_number.to_string (),
                "--brief"
            };
            string stdout_str;
            string stderr_str;
            int exit_status;

            Process.spawn_sync (
                ".",
                spawn_args,
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out stdout_str,
                out stderr_str,
                out exit_status
            );

            if (exit_status == 0) {
                var parts = stdout_str.strip ().split (" ");
                // Format: "VCP 10 C 75 100" (feature current max)
                if (parts.length >= 4 && parts[0] == "VCP" && parts[1] == "10") {
                    return int.parse (parts[3]);
                }
            }
        } catch (Error e) {
            warning ("Failed to get brightness: %s", e.message);
        }

        return -1;
    }

    public async void set_brightness (Display display, int value) {
        // 确保亮度值在有效范围内
        value = value.clamp (0, 100);

        try {
            string[] spawn_args = {
                "/usr/bin/ddcutil", "setvcp", "10", value.to_string (),
                "--display", display.display_number.to_string ()
            };
            int exit_status;

            Process.spawn_sync (
                ".",
                spawn_args,
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                null,
                null,
                out exit_status
            );

            if (exit_status == 0) {
                display.brightness = value;
                brightness_changed (display);
            } else {
                warning ("setvcp failed with exit code %d for display %d",
                    exit_status, display.display_number);
            }
        } catch (Error e) {
            warning ("Failed to set brightness: %s", e.message);
        }
    }

    // 检查显示器是否支持亮度控制
    public async bool supports_brightness (Display display) {
        int brightness = yield get_brightness (display);
        return brightness >= 0;
    }

    public async void refresh_brightness (Display display) {
        int brightness = yield get_brightness (display);
        if (brightness >= 0) {
            display.brightness = brightness;
        }
    }
}
