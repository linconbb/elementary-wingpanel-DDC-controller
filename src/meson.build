wingpanel_dep = dependency('wingpanel', version: '>=3.0.0')
wingpanel_indicatorsdir = wingpanel_dep.get_variable('indicatorsdir', pkgconfig_define: ['libdir', libdir])

conf_data = configuration_data()
conf_data.set('GETTEXT_PACKAGE', gettext_name)
conf_data.set('LOCALEDIR', prefix / get_option('localedir'))

config_in = configure_file(
    input: 'config.vala.in',
    output: '@BASENAME@',
    configuration: conf_data
)

files = files(
    'Indicator.vala',
    'Services/DDCService.vala',
    'Services/Display.vala',
    'Widgets/DisplayWidget.vala',
    'Widgets/PopoverWidget.vala',
    'Widgets/DisplayBrightness.vala'
)

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    wingpanel_dep
]

shared_module(
    meson.project_name(),
    files,
    config_in,
    dependencies: dependencies,
    install: true,
    install_dir : wingpanel_indicatorsdir
)
