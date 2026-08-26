{
  config,
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
    theme = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };
  mod = "SUPER";
  # Directional binds, hyprland's l/r/u/d selectors.
  dirs = {
    left = "l";
    right = "r";
    up = "u";
    down = "d";
  };
  # Renders to hl.bind(keys, <dispatcher>, { flags }); dispatchers are raw lua.
  mkBind = flags: keys: dispatcher: {
    _args =
      [keys (lib.generators.mkLuaInline dispatcher)]
      ++ lib.optional (flags != {}) flags;
  };
  bind = mkBind {};
  bindLocked = mkBind {locked = true;};
  bindRepeat = mkBind {repeating = true;};
  bindRepeatLocked = mkBind {
    repeating = true;
    locked = true;
  };
  bindMouse = mkBind {mouse = true;};
  # code:10 is the `1` key and code:19 the `0` key, so workspace binds stay on
  # the same physical keys under the fr/azerty layout.
  workspaceBinds = lib.concatMap (i: [
    (bind "${mod} + code:1${toString i}" ''hl.dsp.focus({ workspace = "${toString (i + 1)}" })'')
    (bind "${mod} + SHIFT + code:1${toString i}" ''hl.dsp.window.move({ workspace = "${toString (i + 1)}" })'')
  ]) (lib.range 0 9);
in {
  imports = [inputs.noctalia.homeModules.default];

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
      # noctalia's gtk templates recolor adw-gtk3 through an imported noctalia.css;
      # they leave the theme and icon names alone, so they stay set here.
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
      # GTK4 apps use libadwaita, not adw-gtk3, so don't push the GTK3 theme at them.
      gtk4 = {
        theme = null;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
    };

    # The GTK ini keys above are invisible to the XDG portal, which is what
    # ghostty and other portal-aware apps read to pick their light/dark variant.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    home.pointerCursor = {
      enable = true;
      name = cursor.theme;
      inherit (cursor) package size;
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
        config = {
          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
          };

          # Decoration values noctalia's docs recommend for hyprland; its surfaces
          # are translucent, so without blur they read as flat grey.
          decoration = {
            rounding = 20;
            rounding_power = 2;
            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
              # Nix has no hex literals; lua wants the 0xAARRGGBB form.
              color = lib.generators.mkLuaInline "0xee1a1a1a";
            };
            blur = {
              enabled = true;
              size = 3;
              passes = 2;
              vibrancy = 0.1696;
            };
          };

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
        };

        monitor = {
          output = "";
          mode = "preferred";
          position = "auto";
          # 4K panel: everything is unreadable at 1:1.
          scale = 2;
        };

        env = [
          {_args = ["XCURSOR_THEME" cursor.theme];}
          {_args = ["XCURSOR_SIZE" (toString cursor.size)];}
          {_args = ["QT_QPA_PLATFORMTHEME" "qt6ct"];}
        ];

        on = {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("hyprctl setcursor ${cursor.theme} ${toString cursor.size}")
                hl.exec_cmd("noctalia")
              end
            '')
          ];
        };

        # Blur noctalia's own layers and let it run its animations unhindered.
        layer_rule = {
          match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
          no_anim = true;
          blur = true;
          blur_popups = true;
          ignore_alpha = 0.5;
        };

        window_rule = {
          match.class = "dev.noctalia.Noctalia";
          float = true;
          size = [1080 920];
        };

        bind =
          [
            (bind "${mod} + Return" ''hl.dsp.exec_cmd("${apps.terminal}")'')
            (bind "${mod} + B" ''hl.dsp.exec_cmd("${apps.browser}")'')
            (bind "${mod} + F" ''hl.dsp.exec_cmd("${apps.explorer}")'')
            (bind "${mod} + N" ''hl.dsp.exec_cmd("${apps.terminal} -e nvim")'')
            (bind "${mod} + T" ''hl.dsp.exec_cmd("${apps.terminal} -e btop")'')
            (bind "${mod} + Space" ''hl.dsp.exec_cmd("noctalia msg panel-toggle launcher")'')
            (bind "${mod} + S" ''hl.dsp.exec_cmd("noctalia msg panel-toggle control-center")'')
            (bind "${mod} + Escape" ''hl.dsp.exec_cmd("noctalia msg panel-toggle session")'')
            (bind "CTRL + ${mod} + L" ''hl.dsp.exec_cmd("noctalia msg session lock")'')
            (bind "${mod} + V" ''hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard")'')
            # The launcher's emoji provider is triggered by typing its prefix.
            (bind "CTRL + ${mod} + E" ''hl.dsp.exec_cmd("noctalia msg panel-open launcher '/emo '")'')
            (bind "${mod} + W" "hl.dsp.window.close()")
            (bind "${mod} + SHIFT + V" "hl.dsp.window.float()")
            (bind "SHIFT + F11" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
            (bind "ALT + F11" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
            (bind "${mod} + SHIFT + S" ''hl.dsp.exec_cmd("noctalia msg screenshot-region")'')
            (bind "${mod} + Print" ''hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a")'')
            (bind "${mod} + mouse_down" ''hl.dsp.focus({ workspace = "+1" })'')
            (bind "${mod} + mouse_up" ''hl.dsp.focus({ workspace = "-1" })'')

            (bindRepeat "${mod} + code:20" "hl.dsp.window.resize({ x = -100, y = 0, relative = true })")
            (bindRepeat "${mod} + code:21" "hl.dsp.window.resize({ x = 100, y = 0, relative = true })")
            (bindRepeat "${mod} + SHIFT + code:20" "hl.dsp.window.resize({ x = 0, y = -100, relative = true })")
            (bindRepeat "${mod} + SHIFT + code:21" "hl.dsp.window.resize({ x = 0, y = 100, relative = true })")
            (bindRepeat "ALT + Tab" "hl.dsp.window.cycle_next()")
            (bindRepeat "SHIFT + ALT + Tab" "hl.dsp.window.cycle_next({ next = false })")
            (bindRepeat "${mod} + Tab" ''hl.dsp.focus({ workspace = "+1" })'')
            (bindRepeat "${mod} + SHIFT + Tab" ''hl.dsp.focus({ workspace = "-1" })'')

            (bindMouse "${mod} + mouse:272" "hl.dsp.window.drag()")
            (bindMouse "${mod} + mouse:273" "hl.dsp.window.resize()")

            (bindLocked "Print" ''hl.dsp.exec_cmd("noctalia msg screenshot-fullscreen")'')
            (bindLocked "${mod} + comma" ''hl.dsp.exec_cmd("noctalia msg notification-clear-active")'')
            (bindLocked "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("noctalia msg brightness-up")'')
            (bindLocked "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("noctalia msg brightness-down")'')
            (bindLocked "XF86AudioPlay" ''hl.dsp.exec_cmd("noctalia msg media toggle")'')
            (bindLocked "XF86AudioPause" ''hl.dsp.exec_cmd("noctalia msg media toggle")'')
            (bindLocked "XF86AudioNext" ''hl.dsp.exec_cmd("noctalia msg media next")'')
            (bindLocked "XF86AudioPrev" ''hl.dsp.exec_cmd("noctalia msg media previous")'')
            (bindLocked "XF86AudioMute" ''hl.dsp.exec_cmd("noctalia msg volume-mute")'')
            (bindLocked "XF86AudioMicMute" ''hl.dsp.exec_cmd("noctalia msg mic-mute")'')

            (bindRepeatLocked "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("noctalia msg volume-up")'')
            (bindRepeatLocked "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("noctalia msg volume-down")'')
          ]
          ++ lib.mapAttrsToList (key: dir: bind "${mod} + ${key}" ''hl.dsp.focus({ direction = "${dir}" })'') dirs
          ++ lib.mapAttrsToList (key: dir: bind "${mod} + SHIFT + ${key}" ''hl.dsp.window.move({ direction = "${dir}" })'') dirs
          ++ workspaceBinds;
      };
    };

    programs.noctalia = {
      # exec-once above starts the shell, as noctalia's hyprland docs recommend.
      enable = true;
      settings = {
        shell.polkit_agent = true;
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
          # Render the palette into gtk-3.0/gtk-4.0 noctalia.css and qt6ct's colors.
          templates.builtin_ids = ["gtk3" "gtk4" "qt"];
        };
      };
    };

    # qt6ct reads the palette noctalia's qt template writes; the file only exists
    # once the shell has applied a theme, and Fusion is the style that honours it.
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      qt6ctSettings.Appearance = {
        style = "Fusion";
        custom_palette = true;
        color_scheme_path = "${config.xdg.configHome}/qt6ct/colors/noctalia.conf";
        icon_theme = "Papirus-Dark";
      };
    };

    home.packages = [
      pkgs.nixos-icons
      pkgs.hyprpicker
      pkgs.xfce.thunar
    ];
  };
}
