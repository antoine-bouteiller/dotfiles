{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    programs.noctalia = {
      # niri/default.nix starts the shell from spawn-at-startup, as noctalia's docs recommend.
      enable = true;
      settings = {
        shell.polkit_agent = true;
        # Opt-in list; noctalia clones the default `community` source itself at startup.
        plugins.enabled = [
          "raycursive/niri-displays"
          "blackbartblues/audio-switcher"
          "felipeartur/ai-usagebar"
        ];
        wallpaper = {
          # The picker lists this directory; it's the repo's wallpapers as a store path.
          directory = "${./wallpapers}";
          # Rotate at random through them; interval and order keep noctalia's defaults.
          automation.enabled = true;
        };
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
          # Render the palette into gtk-3.0/gtk-4.0 noctalia.css and qt6ct's colors.
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
    ];
  };
}
