{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [inputs.plasma-manager.homeManagerModules.plasma-manager];

  config = lib.mkIf osConfig.desktop.enable {
    programs.plasma = {
      enable = true;

      workspace = {
        clickItemTo = "select";
        lookAndFeel = "org.kde.breezedark.desktop";
        theme = "WhiteSur-dark";
        iconTheme = "WhiteSur";
      };

      fonts = {
        general = {
          family = "Inter";
          pointSize = 10;
        };
        menu = {
          family = "Inter";
          pointSize = 10;
        };
        toolbar = {
          family = "Inter";
          pointSize = 10;
        };
      };

      kwin = {
        titlebarButtons.left = ["close" "minimize" "maximize"];
        titlebarButtons.right = [];
        effects = {
          magicLamp.enable = true;
          overview.enable = true;
        };
      };

      panels = [
        {
          location = "top";
          height = 28;
          widgets = [
            "org.kde.plasma.kickoff"
            "org.kde.plasma.appmenu" # Global Menu
            "org.kde.plasma.panelspacer" # Left Spacer
            "org.kde.plasma.digitalclock" # Center Clock
            "org.kde.plasma.panelspacer" # Right Spacer
            "org.kde.plasma.systemtray"
          ];
        }
        # Bottom Floating Dock
        {
          location = "bottom";
          alignment = "center";
          floating = true;
          hiding = "dodgewindows";
          lengthMode = "fit";
          height = 44;
          widgets = [
            "org.kde.plasma.icontasks" # Icons-only task manager
          ];
        }
      ];
    };

    gtk = {
      enable = true;
      theme = {
        name = "We10X-Dark";
        package = customPkgs.we10x-gtk-theme;
      };
    };

    home.packages = [
      customPkgs.whitesur-icon-theme
      pkgs.whitesur-kde
      pkgs.kdePackages.qtstyleplugin-kvantum
      pkgs.klassy
    ];

    xdg = {
      dataFile = {
        "klassy/presets/whitesur.klpw".source = ./themes/whitesur.klpw;
      };

      configFile = {
        "Kvantum/Fluent-round".source = ./themes/Fluent-round;
        "Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=Fluent-roundDark
        '';
      };
    };
  };
}
