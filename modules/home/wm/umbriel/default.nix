{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  keymap = import ../keymap.nix;
  key = name: keymap.azerty.${name};
  chord = mods: k: lib.concatStringsSep "+" (["Mod"] ++ mods ++ [k]);
  inherit (import ../../../../lib/palette.nix {inherit lib;}) colors;

  bind = name: action: lib.nameValuePair name {inherit action;};
  once = name: action:
    lib.nameValuePair name {
      inherit action;
      repeat = false;
    };
  locked = name: action:
    lib.nameValuePair name {
      inherit action;
      repeat = false;
      allow_when_locked = true;
    };
  lockedRepeat = name: action:
    lib.nameValuePair name {
      inherit action;
      allow_when_locked = true;
    };
  scroll = name: action:
    lib.nameValuePair name {
      inherit action;
      cooldown_ms = 150;
    };
  noctalia = args: "spawn noctalia msg ${args}";
  directionKeys = {
    left = "Left";
    right = "Right";
    up = "Up";
    down = "Down";
  };
  keysFor = dir: [directionKeys.${dir} (key keymap.directionLetters.${dir})];
  dispatchers = {
    float = "window-toggle-floating";
    cycleWidth = "window-cycle-primary-extent";
    cycleWidthBack = "window-cycle-primary-extent-back";
  };
  moveDirection = {
    left = "column-move-left";
    right = "column-move-right";
    up = "window-move-up";
    down = "window-move-down";
  };
  binds =
    [
      (once (chord [] (key "z")) "window-close")
      (once (chord [] (key "return")) "spawn foot")
      (once (chord [] (key "b")) "spawn helium")
      # Umbriel resizes by viewport fractions rather than Niri's logical pixels.
      (bind (chord [] (key "equal")) "window-modify-primary-extent +0.05")
      (bind (chord [] (key "minus")) "window-modify-primary-extent -0.05")
      (bind (chord ["Shift"] (key "equal")) "window-modify-secondary-extent +0.05")
      (bind (chord ["Shift"] (key "minus")) "window-modify-secondary-extent -0.05")
      (once "Mod+F" "spawn luciole")
      (once "Mod+N" "spawn foot -e nvim")
      (once "Mod+T" "spawn foot -e btop")
      (once "Mod+Space" (noctalia "panel-toggle launcher"))
      (once "Mod+S" (noctalia "panel-toggle control-center"))
      (once "Mod+Escape" (noctalia "panel-toggle session"))
      (once "Mod+I" (noctalia "settings-open"))
      (once "Mod+Ctrl+Q" (noctalia "session lock"))
      (once "Mod+V" (noctalia "panel-toggle clipboard"))
      (once "Ctrl+Mod+E" (noctalia "panel-open launcher '/emo '"))
      (once "Shift+F11" "window-toggle-fullscreen")
      (once "Alt+F11" "window-toggle-maximize")
      (once "Mod+Shift+S" (noctalia "screenshot-region"))
      (once "Mod+Print" "spawn wl-color-picker")
      (once "Alt+Tab" "window-focus-last")
      (once "Mod+Tab" "workspace-next")
      (once "Mod+Shift+Tab" "workspace-previous")
      (scroll "Mod+WheelDown" "workspace-next")
      (scroll "Mod+WheelUp" "workspace-previous")
      (locked "Print" (noctalia "screenshot-fullscreen"))
      (locked "Mod+comma" (noctalia "notification-clear-active"))
      (locked "XF86MonBrightnessUp" (noctalia "brightness-up"))
      (locked "XF86MonBrightnessDown" (noctalia "brightness-down"))
      (locked "XF86AudioPlay" (noctalia "media toggle"))
      (locked "XF86AudioPause" (noctalia "media toggle"))
      (locked "XF86AudioNext" (noctalia "media next"))
      (locked "XF86AudioPrev" (noctalia "media previous"))
      (locked "XF86AudioMute" (noctalia "volume-mute"))
      (locked "XF86AudioMicMute" (noctalia "mic-mute"))
      (lockedRepeat "XF86AudioRaiseVolume" (noctalia "volume-up"))
      (lockedRepeat "XF86AudioLowerVolume" (noctalia "volume-down"))
    ]
    ++ map (
      b:
        (
          if b.once or false
          then once
          else bind
        )
        (chord (b.mods or []) (key b.key))
        dispatchers.${b.action}
    )
    keymap.binds
    ++ lib.concatMap (
      dir:
        lib.concatMap (k: [
          (bind (chord [] k) "window-focus-${dir}")
          (bind (chord ["Shift"] k) moveDirection.${dir})
          (bind (chord ["Alt"] k) "column-move-to-output-${dir}")
          (bind (chord ["Alt" "Shift"] k) "output-focus-${dir}")
        ]) (keysFor dir)
    )
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: k: [
        (once (chord [] (key k)) "workspace-switch ${toString index}")
        (once (chord ["Shift"] (key k)) "window-move-to-workspace ${toString index}")
      ])
      keymap.workspaceKeys);
in {
  imports = [inputs.umbriel.homeModules.default];

  config = lib.mkMerge [
    {
      # The upstream package default only has Linux outputs, even when disabled.
      programs.umbriel.package = lib.mkIf (!pkgs.stdenv.hostPlatform.isLinux) null;
    }
    (lib.mkIf config.local.home-manager.desktop.enable {
      programs.umbriel = {
        enable = true;
        settings = {
          general = {
            autostart = [
              "env NOCTALIA_CONFIG_HOME=${lib.escapeShellArg "${config.xdg.configHome}/umbriel"} NOCTALIA_STATE_HOME=${lib.escapeShellArg "${config.xdg.stateHome}/umbriel"} noctalia"
            ];
            show_cheatsheet = false;
            xwayland = true;
            xwayland_native_resolution = true;
          };
          environment.QT_QPA_PLATFORMTHEME = "qt6ct";
          input = {
            keyboard = {
              layout = "fr";
              variant = "azerty";
            };
            touchpad = {
              tap = true;
              natural_scroll = true;
              disable_while_typing = true;
            };
            cursor = {
              theme = "Bibata-Modern-Ice";
              size = 24;
            };
          };
          layout = {
            mode = "scrolling";
            gap = 10;
            extent_presets = keymap.presetWidths;
            scrolling = {
              default_extent_fraction = 0.5;
              center_underfull_strip = false;
              center_focused = "never";
            };
          };
          appearance = {
            prefer_no_csd = true;
            border_width = 2;
            outer_border_width = 0;
            corner_radius = 20;
            title_bar.mode = "off";
            shadow.enabled = true;
          };
          colors = {
            inherit (colors) background;
            text_primary = colors.text;
            text_muted = colors.textMuted;
            accent_primary = colors.blue;
            accent_secondary = colors.blue;
            warning = colors.yellow;
            error = colors.red;
            insert_hint = "${colors.blue}80";
            border = {
              focused = colors.blue;
              unfocused = colors.surface;
            };
            tab_bar = {
              background = colors.surfaceRaised;
              active = colors.blue;
              active_unfocused = colors.surfaceRaised;
              urgent = colors.red;
            };
          };
          window_rule = [
            {
              match.app_id = "^dev[.]noctalia[.]Noctalia$";
              default_floating = true;
              default_floating_size_px = {
                width = 1080;
                height = 920;
              };
            }
          ];
          keybinds = lib.listToAttrs binds;
        };
      };
      home.packages = [pkgs.wl-color-picker];
    })
  ];
}
