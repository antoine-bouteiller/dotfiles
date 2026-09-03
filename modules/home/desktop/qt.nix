{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    # qt6ct reads the palette noctalia's qt template writes; the file only exists
    # once the shell has applied a theme, and Fusion is the style that honours it.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      qt6ctSettings.Appearance = {
        style = "Fusion";
        custom_palette = true;
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
        icon_theme = "Papirus-Dark";
      };
    };
  };
}
