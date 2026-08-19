{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  config = lib.mkIf (osConfig.desktop.enable or false) {
    gtk = {
      enable = true;
      gtk2.force = true;
      # Without this the dconf gtk-theme keeps pointing at a theme that isn't in the
      # closure, so GTK3 apps fall back to light Adwaita under a dark COSMIC session.
      # adw-gtk3 is the theme cosmic-settings-daemon already expects to find.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      # GTK4 apps use libadwaita, not adw-gtk3, so don't push the GTK3 theme at them.
      gtk4 = {
        theme = null;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
      iconTheme = {
        name = "WhiteSur";
        package = customPkgs.whitesur-icon-theme;
      };
    };

    home.packages = [
      pkgs.nixos-icons
    ];
  };
}
