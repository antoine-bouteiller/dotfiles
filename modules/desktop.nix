{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.desktop;
in {
  options.desktop = {
    enable = lib.mkEnableOption "KDE Plasma Desktop";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "WhiteSur-dark";
    };
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      whitesur-kde
    ];
  };
}
