project(
    'ddcbrightness',
    'vala', 'c',
    version: '1.0.0',
    meson_version: '>=0.58.0'
)

gettext_name = 'io.elementary.wingpanel.ddcbrightness'
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
libdir = prefix / get_option('libdir')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')
add_project_arguments('-DG_LOG_DOMAIN="io.elementary.wingpanel.ddcbrightness"', language:'c')

subdir('data')
subdir('po')
subdir('src')
