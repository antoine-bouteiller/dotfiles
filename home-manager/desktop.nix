{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [inputs.caelestia-shell.homeManagerModules.default];

  config = lib.mkIf (osConfig.desktop.enable or false) {
    gtk = {
      enable = true;
      gtk2.force = true;
      # GTK3 apps otherwise fall back to light Adwaita in a dark session; adw-gtk3
      # is the theme that matches libadwaita's dark styling.
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

    home.pointerCursor = {
      enable = true;
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
      gtk.enable = true;
    };

    xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;

    programs.caelestia = {
      enable = true;
      cli.enable = true;
      # hyprland.lua starts the shell on compositor start.
      systemd.enable = false;
      settings.general.apps = {
        terminal = ["ghostty"];
        explorer = ["nautilus"];
      };
    };

    services.cliphist.enable = true;
    services.hyprpolkitagent.enable = true;

    home.packages = [
      pkgs.nixos-icons
      pkgs.hyprpicker
      pkgs.nautilus
    ];
  };
}
