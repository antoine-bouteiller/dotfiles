{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    programs.noctalia = {
      enable = true;
      settings = {
        shell = {
          polkit_agent = true;
          settings_show_advanced = false;
          panel.open_near_click_control_center = true;
        };
        plugins.enabled = [
          "raycursive/niri-displays"
          "felipeartur/ai-usagebar"
        ];
        plugin_settings."felipeartur/ai-usagebar".panel_open_near_click = true;
        bar.default = {
          start = ["launcher" "niri-display" "workspaces"];
          end = [
            "media"
            "ai-usagebar"
            "tray"
            "notifications"
            "clipboard"
            "network"
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
          media.enabled = false;
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
          source = "builtin";
          builtin = "Catppuccin";
          templates.builtin_ids = ["gtk3" "gtk4" "qt" "foot" "niri" "btop"];
        };
      };
    };

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

    # Same story for the foot and btop templates: their apply hooks would have to
    # edit read-only config, so the theme is wired in here instead. foot refuses to
    # start on a missing include, hence the placeholder for the pre-first-theme window.
    programs.foot.settings.main.include = "${config.xdg.configHome}/foot/themes/noctalia";
    programs.btop.settings.color_theme = "noctalia";

    home.activation.footNoctaliaTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p ${config.xdg.configHome}/foot/themes
      run touch -a ${config.xdg.configHome}/foot/themes/noctalia
    '';

    home.packages = [
      pkgs.nixos-icons
      # `felipeartur/ai-usagebar` runs the CLI by name off PATH.
      customPkgs.ai-usagebar
    ];
  };
}
