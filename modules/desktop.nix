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
        # Submitting an empty password is what hands the PAM conversation over to
        # pam_fprintd, so this is what makes fingerprint login work at the greeter.
        auth.allow_empty_password = true;
      };
    };

    environment.sessionVariables.NIXOS_OZONE_WL = 1;

    # noctalia's gtk template applies itself through gsettings.
    programs.dconf.enable = true;

    # noctalia's battery and power-profile widgets talk to these daemons over D-Bus.
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    # No system76-scheduler here: its cfs-profiles write sysctls that EEVDF removed in
    # 6.6, and its foreground boost needs a GNOME/COSMIC client to report the focused
    # window, so under Hyprland only the de-boost half lands -- launcher-started apps
    # match its system-services profile (nice 12, idle IO) and get starved.

    # Hyprland only ships its own portal; GTK provides the file chooser.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
