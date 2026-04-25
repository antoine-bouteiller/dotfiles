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
    enable = lib.mkEnableOption "KDE Plasma Desktop";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "WhiteSur-dark";
    };
    services.desktopManager.plasma6.enable = true;

    programs.dconf.enable = true;

    environment.systemPackages = [
      pkgs.whitesur-kde
      customPkgs.we10x-gtk-theme
    ];

    fonts.packages = [
      pkgs.nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig.defaultFonts.monospace = ["JetBrainsMono Nerd Font Mono"];
  };
}
