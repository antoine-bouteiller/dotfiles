{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.desktop;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  options.desktop = {
    enable = lib.mkEnableOption "Hyprland Desktop";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # tuigreet has no theming/dependency baggage; it just execs the uwsm session.
    services.greetd = {
      enable = true;
      settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
    };

    # caelestia's lock screen authenticates against a pam service of its own name.
    security.pam.services.caelestia = {};

    environment.sessionVariables.NIXOS_OZONE_WL = 1;

    services.system76-scheduler.enable = true;

    # Hyprland only ships its own portal; GTK provides the file chooser.
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    environment.systemPackages = [
      customPkgs.whitesur-icon-theme
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      # Fonts caelestia-shell renders with by default.
      material-symbols
      rubik
      nerd-fonts.caskaydia-cove
    ];
  };
}
