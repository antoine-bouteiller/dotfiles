{
  config,
  osConfig,
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
in {
  config = lib.mkIf (osConfig.desktop.enable or false) {
    home.pointerCursor = {
      enable = true;
      name = cursor.theme;
      inherit (cursor) package size;
      gtk.enable = true;
    };

    # There is no home-manager module for niri, and its config is a single KDL
    # file; only the binds are worth generating.
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

      output "eDP-1" {
          // 4K panel: everything is unreadable at 1:1.
          scale 2
      }

      layout {
          gaps 10
          // A single 2px frame: the focus ring would double up on the border,
          // and noctalia's template colors both, whichever is drawn.
          border {
              width 2
          }
          focus-ring {
              off
          }
          shadow {
              on
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

      // noctalia's niri template renders niri/noctalia.kdl and expects this line
      // in config.kdl -- which home-manager owns and makes read-only, so the
      // template's own apply hook cannot add it. Spelled exactly as the hook
      // greps for it, so it leaves the file alone.
      include "noctalia.kdl"
    '';

    # niri refuses to load a config whose include is missing, which is the window
    # before noctalia has applied a theme for the first time.
    home.activation.niriNoctaliaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p ${config.xdg.configHome}/niri
      run touch -a ${config.xdg.configHome}/niri/noctalia.kdl
    '';

    # Only referenced by binds.nix.
    home.packages = [
      pkgs.wl-color-picker
      pkgs.thunar
    ];
  };
}
