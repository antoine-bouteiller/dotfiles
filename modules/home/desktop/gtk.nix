{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    gtk = {
      enable = true;
      gtk2.force = true;
      # GTK3 apps otherwise fall back to light Adwaita in a dark session; adw-gtk3
      # is the theme that matches libadwaita's dark styling.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      # noctalia's gtk templates recolor adw-gtk3 through an imported noctalia.css;
      # they leave the theme and icon names alone, so they stay set here.
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      # GTK4 apps use libadwaita, not adw-gtk3, so don't push the GTK3 theme at them.
      gtk4 = {
        theme = null;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
    };

    # The GTK ini keys above are invisible to the XDG portal, which is what
    # portal-aware apps read to pick their light/dark variant.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
