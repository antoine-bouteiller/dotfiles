{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.local.home-manager.desktop.enable {
    gtk = {
      enable = true;
      gtk2.force = true;
      font = {
        name = "Inter";
        size = 11;
      };
      # GTK3 apps otherwise fall back to light Adwaita in a dark session; adw-gtk3
      # is the theme that matches libadwaita's dark styling.
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      # noctalia's gtk templates recolor adw-gtk3 through an imported noctalia.css;
      # they leave the theme and icon names alone, so they stay set here.
      iconTheme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-icon-theme;
      };
      gtk3 = {
        extraConfig.gtk-application-prefer-dark-theme = true;
        extraCss = ''
          @import url("noctalia.css");

          .thunar toolbar {
            background-color: @window_bg_color;
            border-bottom: 1px solid alpha(@window_fg_color, 0.08);
            padding: 8px;
          }

          .thunar toolbar button {
            border-radius: 8px;
            min-width: 16px;
            min-height: 16px;
            padding: 6px;
            margin: 0 2px;
          }

          .thunar toolbar button,
          .thunar toolbar button:focus,
          .thunar toolbar entry:focus {
            -gtk-outline-radius: 8px;
          }

          /* Thunar allocates fixed widths to breadcrumb arrows. */
          .thunar toolbar .path-bar button {
            min-width: 0;
            padding: 4px;
            margin: 0;
          }

          .thunar toolbar .path-bar button.toggle {
            margin: 0 3px;
          }

          .thunar toolbar .path-bar button:disabled {
            background: none;
            border-color: transparent;
            box-shadow: none;
            opacity: 0;
          }

          .thunar toolbar entry {
            border-radius: 8px;
            padding: 4px 12px;
          }

          .thunar .sidebar {
            background-color: @sidebar_bg_color;
            border: none;
            padding: 12px 16px;
          }

          .thunar .sidebar treeview {
            background-color: @sidebar_bg_color;
            color: @sidebar_fg_color;
            -GtkTreeView-vertical-separator: 12;
          }

          /* Thunar resolves sidebar symbolic icons using the unselected color. */
          .thunar .sidebar treeview:selected,
          .thunar .sidebar treeview:selected:backdrop {
            background-color: mix(@sidebar_bg_color, @accent_bg_color, 0.18);
            color: @sidebar_fg_color;
            border-radius: 8px;
          }

          .thunar paned > separator {
            background-color: alpha(@window_fg_color, 0.08);
            min-width: 1px;
            min-height: 1px;
          }

          .thunar statusbar {
            border-top: 1px solid alpha(@window_fg_color, 0.08);
            padding: 6px 12px;
          }
        '';
      };
      # GTK4 apps use libadwaita, not adw-gtk3, so don't push the GTK3 theme at them.
      gtk4 = {
        theme = null;
        extraConfig.gtk-application-prefer-dark-theme = true;
      };
    };

    # Noctalia creates this file before Home Manager takes ownership of it.
    xdg.configFile."gtk-3.0/gtk.css".force = true;

    xfconf.settings = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      thunar = {
        last-menubar-visible = false;
        last-location-bar = "ThunarLocationButtons";
        last-separator-position = 240;
        misc-small-toolbar-icons = true;
      };
    };

    # The GTK ini keys above are invisible to the XDG portal, which is what
    # portal-aware apps read to pick their light/dark variant.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };
}
