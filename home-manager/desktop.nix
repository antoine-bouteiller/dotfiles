{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.cosmic-manager.homeManagerModules.cosmic-manager
  ];

  config = lib.mkIf (osConfig.desktop.enable or false) {
    wayland.desktopManager.cosmic = {
      enable = true;

      applets.app-list = {
        settings = {
          favorites = [
            "ghostty"
            "helium"
            "zed"
            "plex-desktop"
            "telegram"
          ];
        };
      };

      panels = [
        {
          name = "Panel";
          anchor = {
            __type = "enum";
            variant = "Top";
          };
          expand_to_edges = true;
          anchor_gap = false;
          margin = 0;
          opacity = 0.8;
          size = {
            __type = "enum";
            variant = "XS";
          };
          plugins_center = {
            __type = "optional";
            value = ["com.system76.CosmicAppletTime"];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [
                [
                  "com.system76.CosmicPanelWorkspacesButton"
                  "com.system76.CosmicPanelAppButton"
                ]
                [
                  "com.system76.CosmicAppletStatusArea"
                  "com.system76.CosmicAppletAudio"
                  "com.system76.CosmicAppletNetwork"
                  "com.system76.CosmicAppletBluetooth"
                  "com.system76.CosmicAppletNotifications"
                  "com.system76.CosmicAppletBattery"
                  "com.system76.CosmicAppletPower"
                ]
              ];
            };
          };
        }
        {
          name = "Dock";
          anchor = {
            __type = "enum";
            variant = "Bottom";
          };
          expand_to_edges = false;
          anchor_gap = true;
          margin = 8;
          opacity = 0.6;
          # Max half the dock's inner height (size M 48px − 2×4 padding = 40 → 20);
          # anything larger is a cosmic_corner_radius_layer_v1 radius_too_large
          # protocol error that crash-loops cosmic-panel. The Appearance "Round"
          # style writes an unclamped 160 here — this pin overrides it on apply.
          border_radius = 20;
          size = {
            __type = "enum";
            variant = "M";
          };
          plugins_center = {
            __type = "optional";
            value = [
              "com.system76.CosmicAppList"
              "com.system76.CosmicAppletWorkspace"
            ];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [
                []
                []
              ];
            };
          };
          autohide_behavior = {
            wait_time = 1000;
            transition_time = 200;
            handle_size = 4;
            unhide_delay = 200;
          };
        }
      ];

      configFile = let
        # COSMIC 1.5 theme builder entries the pinned cosmic-manager has no
        # options for: frosted glass toggles (it only knows the defunct v1
        # `is_frosted` bool) and the Appearance "Round" interface style radii,
        # captured from what cosmic-settings writes.
        radius = v: {
          __type = "tuple";
          value = [v v v v];
        };
        builder = {
          version = 2;
          entries = {
            frosted_system_interface = true;
            frosted_panel = true;
            frosted_windows = false;
            frosted_applets = true;
            corner_radii = {
              radius_0 = radius 0.0;
              radius_xs = radius 4.0;
              radius_s = radius 8.0;
              radius_m = radius 16.0;
              radius_l = radius 32.0;
              # The "Round" preset writes 160.0. Applets send theme-derived
              # radii for their own surfaces and cosmic-panel 1.5.0 forwards
              # them unclamped (inverted skip in commit_wlr), so oversized
              # values are a radius_too_large protocol error that crash-loops
              # the panel on startup — the Settings UI only survives because
              # live surfaces are already full-sized. 40 is verified safe.
              radius_xl = radius 40.0;
            };
          };
        };
      in {
        "com.system76.CosmicPanel.Dock".entries.autohide = lib.mkForce {
          __type = "enum";
          variant = "OnOverlap";
        };
        "com.system76.CosmicTheme.Dark.Builder" = builder;
        "com.system76.CosmicTheme.Light.Builder" = builder;
      };

      compositor = {
        active_hint = false;

        input_touchpad = {
          state = {
            __type = "enum";
            variant = "Enabled";
          };
          click_method = {
            __type = "optional";
            value = {
              __type = "enum";
              variant = "Clickfinger";
            };
          };
          tap_config = {
            __type = "optional";
            value = {
              enabled = true;
              button_map = {
                __type = "optional";
                value = {
                  __type = "enum";
                  variant = "LeftRightMiddle";
                };
              };
              drag = true;
              drag_lock = false;
            };
          };
          scroll_config = {
            __type = "optional";
            value = {
              method = {
                __type = "optional";
                value = {
                  __type = "enum";
                  variant = "TwoFinger";
                };
              };
              natural_scroll = {
                __type = "optional";
                value = true;
              };
              scroll_button = {
                __type = "optional";
                value = null;
              };
              scroll_factor = {
                __type = "optional";
                value = 0.4;
              };
            };
          };
        };
      };

      shortcuts = [
        {
          key = "Alt+Space";
          action = {
            __type = "enum";
            variant = "System";
            value = [
              {
                __type = "enum";
                variant = "Launcher";
              }
            ];
          };
        }
        {
          key = "Alt+Ctrl+Q";
          action = {
            __type = "enum";
            variant = "System";
            value = [
              {
                __type = "enum";
                variant = "LockScreen";
              }
            ];
          };
        }
      ];

      appearance.toolkit = {
        monospace_font = {
          family = "JetBrainsMono Nerd Font";
          stretch = {
            __type = "enum";
            variant = "Normal";
          };
          style = {
            __type = "enum";
            variant = "Normal";
          };
          weight = {
            __type = "enum";
            variant = "Normal";
          };
        };
      };
    };

    gtk = {
      enable = true;
      gtk2.force = true;
      iconTheme = {
        name = "WhiteSur";
        package = customPkgs.whitesur-icon-theme;
      };
    };

    home.packages = [
      pkgs.nixos-icons
    ];
  };
}
