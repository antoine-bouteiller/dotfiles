{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [inputs.plasma-manager.homeModules.plasma-manager];

  config = lib.mkIf (osConfig.desktop.enable or false) {
    programs.plasma = {
      enable = true;

      workspace = {
        clickItemTo = "select";
        theme = "WhiteSur-dark";
        iconTheme = "WhiteSur";
        windowDecorations = {
          library = "org.kde.klassy";
          theme = "Klassy";
        };
      };

      fonts = {
        general = {
          family = "Inter";
          pointSize = 11;
        };
        menu = {
          family = "Inter";
          pointSize = 11;
        };
        toolbar = {
          family = "Inter";
          pointSize = 11;
        };
      };

      kwin = {
        titlebarButtons.left = ["close" "minimize" "maximize"];
        titlebarButtons.right = [];
        effects.minimization.animation = "magiclamp";
        effects.blur = {
          enable = true;
          strength = 10;
          noiseStrength = 0;
        };
      };

      panels = [
        {
          location = "top";
          height = 28;
          widgets = [
            {
              name = "org.kde.plasma.kicker";
              config.General.icon = "nix-snowflake-white";
            }
            "org.kde.plasma.appmenu"
            "org.kde.plasma.panelspacer"
            "org.kde.plasma.digitalclock"
            "org.kde.plasma.panelspacer"
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
          height = 66;
          widgets = [
            "org.kde.plasma.icontasks" # Icons-only task manager
          ];
        }
      ];

      configFile = {
        "kdeglobals"."KDE"."widgetStyle" = "kvantum";
      };
    };

    gtk = {
      enable = true;
      gtk3.theme = {
        name = "We10X-Dark";
        package = customPkgs.we10x-gtk-theme;
      };
      gtk4.theme = {
        name = "We10X-Dark";
        package = customPkgs.we10x-gtk-theme;
      };
      gtk2.force = true;
      iconTheme = {
        name = "WhiteSur";
        package = customPkgs.whitesur-icon-theme;
      };
      font = {
        name = "Inter";
        size = 11;
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    home.pointerCursor = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    home.packages = [
      pkgs.kdePackages.qtstyleplugin-kvantum
      pkgs.klassy
      pkgs.inter
      pkgs.nixos-icons
    ];

    xdg = {
      dataFile = {
        "klassy/presets/whitesur.klpw".source = ./themes/whitesur.klpw;
      };

      configFile = {
        "Kvantum/Fluent-roundDark".source = ./themes/Fluent-round;
        "Kvantum/kvantum.kvconfig".text = ''
          [General]
          theme=Fluent-roundDark
        '';
      };
    };

    home.activation.applyKlassyPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run env QT_QPA_PLATFORM=offscreen ${pkgs.klassy}/bin/klassy-settings \
        --import-preset "${./themes/whitesur.klpw}" -f || true
      run env QT_QPA_PLATFORM=offscreen ${pkgs.klassy}/bin/klassy-settings \
        --load-windeco-preset "WhiteSur" || true
    '';
  };
}
