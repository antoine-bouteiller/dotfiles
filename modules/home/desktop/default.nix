{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args:
mkModule args "local.home-manager.desktop" {
  description = "Niri desktop session: gtk/qt theming and the noctalia shell";
  imports = [inputs.noctalia.homeModules.default];
  config = _: {
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
    # portal-aware apps read to pick their light/dark variant.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    programs.noctalia = {
      # niri/default.nix starts the shell from spawn-at-startup, as noctalia's docs recommend.
      enable = true;
      settings = {
        shell.polkit_agent = true;
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

    programs.zsh.shellAliases.sudo = "pkexec";

    home.packages = [
      pkgs.nixos-icons
    ];
  };
}
