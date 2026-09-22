{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;
in {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    programs.noctalia = {
      enable = true;
      customPalettes.nix.dark = {
        mPrimary = colors.textSecondary;
        mOnPrimary = colors.background;
        # Secondary also colors tooltip labels, so it must contrast with the surface.
        mSecondary = colors.textSubtle;
        mOnSecondary = colors.background;
        mTertiary = colors.textFaint;
        mOnTertiary = colors.background;
        mError = colors.red;
        mOnError = colors.background;
        mSurface = colors.surface;
        mOnSurface = colors.text;
        mSurfaceVariant = colors.surfaceRaised;
        mOnSurfaceVariant = colors.textSecondary;
        mOutline = colors.surfaceHover;
        mShadow = colors.black;
        mHover = colors.surfaceHover;
        mOnHover = colors.text;
        # Keep ANSI colors semantic rather than deriving green/yellow from UI accents.
        terminal = rec {
          inherit (colors) background;
          foreground = colors.text;
          cursor = colors.text;
          cursorText = colors.background;
          selectionBg = colors.surfaceRaised;
          selectionFg = colors.text;
          normal = {
            inherit (colors) red green yellow blue magenta cyan white;
            black = colors.textFaint;
          };
          bright = normal // {black = colors.textSubtle;};
        };
      };
      settings = {
        idle.behavior = {
          screen-off = {
            enabled = true;
            timeout = 300;
            action = "screen_off";
          };
          lock-and-suspend = {
            enabled = true;
            timeout = 900;
            action = "lock_and_suspend";
          };
        };
        shell = {
          font_family = "Inter";
          polkit_agent = true;
          greeter_sync.auto_sync = true;
          settings_show_advanced = false;
          panel = {
            open_near_click_control_center = true;
          };
        };
        plugins.enabled = [
          "raycursive/niri-displays"
          "felipeartur/ai-usagebar"
          "nightwatch75/dns-switcher"
          "davemhammer/tailscale"
        ];
        plugin_settings."felipeartur/ai-usagebar" = {
          panel_open_near_click = true;
        };
        # The ISP resolver filters some domains; switch to a public one when needed.
        plugin_settings."nightwatch75/dns-switcher" = {
          providers = "cloudflare";
        };
        bar.default = {
          color = "on_surface";
          start = ["launcher" "niri-display" "workspaces"];
          end = [
            "media"
            "ai-usagebar"
            "dns-switcher"
            "tray"
            "notifications"
            "clipboard"
            "network"
            "tailscale"
            "bluetooth"
            "volume"
            "brightness"
            "battery"
            "session"
          ];
        };
        widget = {
          "ai-usagebar".type = "felipeartur/ai-usagebar:bar";
          "niri-display".type = "raycursive/niri-displays:bar";
          "dns-switcher".type = "nightwatch75/dns-switcher:dns-switcher";
          "tailscale".type = "davemhammer/tailscale:status";
          media.enabled = false;
          workspaces = {
            focused_color = colors.blue;
            focused_output_only = true;
          };
        };
        control_center = {
          sidebar = "none";
          sidebar_section = "none";
          shortcuts = map (type: {inherit type;}) [
            "wifi"
            "bluetooth"
            "caffeine"
            "nightlight"
            "power_profile"
          ];
        };
        wallpaper = {
          directory = "${./wallpapers}";
          automation.enabled = true;
        };
        theme = {
          mode = "dark";
          source = "custom";
          custom_palette = "nix";
          templates.builtin_ids = ["gtk3" "gtk4" "qt" "foot"];
        };
      };
    };

    # Mask redundant launcher entries without removing the underlying tools.
    xdg.dataFile =
      lib.genAttrs [
        "applications/qt5ct.desktop"
        "applications/qt6ct.desktop"
        "applications/thunar-settings.desktop"
        "applications/footclient.desktop"
        "applications/foot-server.desktop"
        "applications/dev.noctalia.Noctalia.desktop"
      ] (_: {
        text = ''
          [Desktop Entry]
          Hidden=true
        '';
      });

    # noctalia ships a single entry whose Exec is `noctalia --daemon`, so launching it
    # from the launcher does nothing once the shell is already running; settings live in
    # a desktop *action*, which the launcher doesn't list. This is that action as an entry.
    xdg.desktopEntries.noctalia-settings = {
      name = "Noctalia Settings";
      exec = "noctalia msg settings-open";
      icon = "noctalia";
      terminal = false;
      categories = ["Settings" "DesktopSettings"];
    };

    # The foot template's apply hook would have to edit read-only config, so the
    # theme is wired in here instead. foot refuses to start on a missing include,
    # hence the placeholder for the pre-first-theme window.
    programs.foot.settings.main.include = "${config.xdg.configHome}/foot/themes/noctalia";

    home.activation.footNoctaliaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p ${config.xdg.configHome}/foot/themes
      run touch -a ${config.xdg.configHome}/foot/themes/noctalia
    '';

    home.packages = [
      pkgs.nixos-icons
      # `felipeartur/ai-usagebar` runs the CLI by name off PATH.
      customPkgs.ai-usagebar
      # `nightwatch75/dns-switcher`'s lookup tester shells out to `dig`.
      pkgs.dnsutils
    ];
  };
}
