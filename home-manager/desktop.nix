{
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  apps = {
    terminal = "ghostty";
    browser = "helium";
    explorer = "thunar";
  };
  cursor = {
    theme = "Adwaita";
    size = 24;
  };
  # Directional binds, hyprland's l/r/u/d suffixes.
  dirs = {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  };
  # code:10 is the `1` key and code:19 the `0` key, so workspace binds stay on
  # the same physical keys under the fr/azerty layout.
  workspaceBinds = lib.concatMap (i: [
    "$mod, code:1${toString i}, workspace, ${toString (i + 1)}"
    "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString (i + 1)}"
  ]) (lib.range 0 9);
in {
  imports = [inputs.caelestia-shell.homeManagerModules.default];

  config = lib.mkIf (osConfig.desktop.enable or false) {
    gtk = {
      enable = true;
      gtk2.force = true;
      # GTK3 apps otherwise fall back to light Adwaita in a dark session; adw-gtk3
      # is the theme that matches libadwaita's dark styling.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      # GTK4 apps use libadwaita, not adw-gtk3, so don't push the GTK3 theme at them.
      gtk4 = {
        theme = null;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
    };

    home.pointerCursor = {
      enable = true;
      name = cursor.theme;
      package = pkgs.adwaita-icon-theme;
      inherit (cursor) size;
      gtk.enable = true;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # The compositor and its portal come from the NixOS module.
      package = null;
      portalPackage = null;
      # uwsm owns the session.
      systemd.enable = false;

      settings = {
        "$mod" = "SUPER";

        monitor = ",preferred,auto,1";

        env = [
          "XCURSOR_THEME,${cursor.theme}"
          "XCURSOR_SIZE,${toString cursor.size}"
        ];

        exec-once = [
          "hyprctl setcursor ${cursor.theme} ${toString cursor.size}"
          "caelestia shell -d"
        ];

        general = {
          layout = "dwindle";
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };

        dwindle = {
          preserve_split = true;
          smart_resizing = true;
        };

        decoration.rounding = 10;

        input = {
          kb_layout = "fr";
          kb_variant = "azerty";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
          };
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

        bind =
          [
            "$mod, Return, exec, ${apps.terminal}"
            "$mod, B, exec, ${apps.browser}"
            "$mod, F, exec, ${apps.explorer}"
            "$mod, N, exec, ${apps.terminal} -e nvim"
            "$mod, T, exec, ${apps.terminal} -e btop"
            "$mod, Space, global, caelestia:launcher"
            "$mod, Escape, global, caelestia:session"
            "CTRL $mod, L, global, caelestia:lock"
            "$mod, V, exec, caelestia clipboard"
            "CTRL $mod, E, exec, caelestia emoji -p"
            "$mod, W, killactive"
            "$mod SHIFT, V, togglefloating"
            "SHIFT, F11, fullscreen, 0"
            "ALT, F11, fullscreen, 1"
            "$mod SHIFT, S, global, caelestia:screenshot"
            "$mod, Print, exec, pkill hyprpicker || hyprpicker -a"
            "$mod, mouse_down, workspace, +1"
            "$mod, mouse_up, workspace, -1"
          ]
          ++ lib.mapAttrsToList (key: dir: "$mod, ${key}, movefocus, ${dir}") dirs
          ++ lib.mapAttrsToList (key: dir: "$mod SHIFT, ${key}, movewindow, ${dir}") dirs
          ++ workspaceBinds;

        binde = [
          "$mod, code:20, resizeactive, -100 0"
          "$mod, code:21, resizeactive, 100 0"
          "$mod SHIFT, code:20, resizeactive, 0 -100"
          "$mod SHIFT, code:21, resizeactive, 0 100"
          "ALT, Tab, cyclenext"
          "SHIFT ALT, Tab, cyclenext, prev"
          "$mod, Tab, workspace, +1"
          "$mod SHIFT, Tab, workspace, -1"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindl = [
          ", Print, exec, caelestia screenshot"
          "$mod, comma, global, caelestia:clearNotifs"
          ", XF86MonBrightnessUp, global, caelestia:brightnessUp"
          ", XF86MonBrightnessDown, global, caelestia:brightnessDown"
          ", XF86AudioPlay, global, caelestia:mediaToggle"
          ", XF86AudioPause, global, caelestia:mediaToggle"
          ", XF86AudioNext, global, caelestia:mediaNext"
          ", XF86AudioPrev, global, caelestia:mediaPrev"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ];

        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ];
      };
    };

    programs.caelestia = {
      enable = true;
      cli.enable = true;
      # exec-once above starts the shell on compositor start.
      systemd.enable = false;
      settings.general.apps = {
        terminal = [apps.terminal];
        explorer = [apps.explorer];
      };
    };

    services.cliphist.enable = true;
    services.hyprpolkitagent.enable = true;

    home.packages = [
      pkgs.nixos-icons
      pkgs.hyprpicker
      # caelestia's scheme templates cover thunar, not nautilus.
      pkgs.xfce.thunar
      # `caelestia scheme` points dconf's icon-theme at Papirus-<mode>.
      pkgs.papirus-icon-theme
    ];
  };
}
