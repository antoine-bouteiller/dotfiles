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
    nixpkgs.overlays = [
      (final: prev: {
        kdePackages =
          prev.kdePackages
          // {
            dolphin = prev.kdePackages.dolphin.overrideAttrs (old: {
              postPatch =
                (old.postPatch or "")
                + ''
                  sed -i 's/placesDock->setWidget(m_placesPanel);/placesDock->setWidget(m_placesPanel);\n    placesDock->setContentsMargins(16, 0, 8, 0);/g' src/dolphinmainwindow.cpp
                '';
            });
          };
      })
    ];

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
