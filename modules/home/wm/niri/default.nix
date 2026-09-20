{
  config,
  lib,
  pkgs,
  ...
}: let
  cursor = {
    theme = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  binds = import ./binds.nix {inherit lib;};
  inherit (import ../keymap.nix) presetWidths;
  inherit (import ../../../../lib/palette.nix {inherit lib;}) colors;
in {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    home.pointerCursor = {
      enable = true;
      name = cursor.theme;
      inherit (cursor) package size;
      gtk.enable = true;
    };

    # There is no home-manager module for niri; keep its config in a single KDL file.
    xdg.configFile."niri/config.kdl".text = ''
      input {
          keyboard {
              xkb {
                  layout "fr"
                  variant "azerty"
              }
          }
          touchpad {
              tap
              natural-scroll
              dwt
          }
      }

      ${config.local.home-manager.desktop.extraNiriConfig}
      layout {
          gaps 10
          preset-column-widths {
      ${lib.concatMapStringsSep "\n" (w: "        proportion ${toString w}") presetWidths}
          }
          // A single 2px frame: the focus ring would double up on the border.
          border {
              width 2
              active-color "${colors.blue}"
              inactive-color "${colors.surface}"
              urgent-color "${colors.red}"
          }
          focus-ring {
              off
              active-color "${colors.blue}"
              inactive-color "${colors.surface}"
              urgent-color "${colors.red}"
          }
          tab-indicator {
              active-color "${colors.blue}"
              inactive-color "${colors.surfaceRaised}"
              urgent-color "${colors.red}"
          }
          insert-hint {
              color "${colors.blue}80"
          }
          shadow {
              on
          }
      }

      recent-windows {
          highlight {
              active-color "${colors.blue}"
              urgent-color "${colors.red}"
          }
      }

      // Ask clients for server-side decorations: foot and friends drop their own
      // titlebar and niri's border becomes the only frame.
      prefer-no-csd

      cursor {
          xcursor-theme "${cursor.theme}"
          xcursor-size ${toString cursor.size}
      }

      environment {
          QT_QPA_PLATFORMTHEME "qt6ct"
          // niri has no built-in Xwayland; xwayland-satellite below provides :12.
          DISPLAY ":12"
      }

      // niri opens its keybind cheatsheet on every start otherwise.
      hotkey-overlay {
          skip-at-startup
      }

      spawn-at-startup "noctalia"
      spawn-at-startup "xwayland-satellite" ":12"

      window-rule {
          geometry-corner-radius 20
          clip-to-geometry true
      }

      window-rule {
          match app-id="dev.noctalia.Noctalia"
          open-floating true
          default-column-width { fixed 1080; }
          default-window-height { fixed 920; }
      }

      binds {
      ${lib.concatMapStringsSep "\n" (b: "    ${b}") binds}
      }
    '';

    # Only referenced by binds.nix.
    home.packages = [
      pkgs.wl-color-picker
      pkgs.thunar
    ];
  };
}
