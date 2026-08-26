{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop;
in {
  imports = [inputs.noctalia-greeter.nixosModules.default];

  options.desktop = {
    enable = lib.mkEnableOption "Hyprland Desktop";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # The greeter enables greetd and points it at its own wlroots compositor; the
    # session list comes from the wayland-sessions entries hyprland's uwsm unit ships.
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        appearance = {
          scheme = "Catppuccin";
          theme_mode = "dark";
        };
        keyboard = {
          layout = "fr";
          variant = "azerty";
        };
        # The greeter runs as the greetd user, so the theme has to be pointed at.
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };
      };
    };

    environment.sessionVariables.NIXOS_OZONE_WL = 1;

    # noctalia's gtk template applies itself through gsettings.
    programs.dconf.enable = true;

    # noctalia's battery and power-profile widgets talk to these daemons over D-Bus.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    services.system76-scheduler.enable = true;

    # Hyprland only ships its own portal; GTK provides the file chooser.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
