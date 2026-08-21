{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.local.home-manager.herdr.enable = lib.mkEnableOption "HerdR terminal session manager";

  config = lib.mkIf config.local.home-manager.herdr.enable {
    home.packages = [package];
    xdg.configFile."herdr/config.toml" = {
      force = true;
      source = (pkgs.formats.toml {}).generate "herdr-config" {
        onboarding = false;
        theme = {
          # JetBrains Islands Dark: https://github.com/mbadolato/iTerm2-Color-Schemes/blob/master/yaml/JetBrains%20Islands%20Dark.yml
          name = "one-dark";
          auto_switch = false;
          custom = {
            accent = "#548af7";
            panel_bg = "#191a1c";
            surface0 = "#2a4371";
            surface1 = "#2a4371";
            surface_dim = "#191a1c";
            overlay0 = "#7a7e85";
            overlay1 = "#d1d3d9";
            text = "#bcbec4";
            subtext0 = "#7a7e85";
            mauve = "#c77dbb";
            green = "#6aab73";
            yellow = "#cf8e6d";
            red = "#f75464";
            blue = "#56a8f5";
            teal = "#2aacb8";
            peach = "#f0ac81";
          };
        };

        terminal.new_cwd = "follow";

        keys = {
          prefix = "ctrl+space";
          reload_config = "prefix+q";
          help = "prefix+?";
          detach = "prefix+d";
          copy_mode = "prefix+[";
          split_horizontal = ["prefix+h" "alt+enter"];
          split_vertical = ["prefix+v" "alt+shift+enter"];
          close_pane = ["prefix+x" "alt+esc"];
          zoom = "prefix+z";
          last_pane = "prefix+;";
          focus_pane_left = "ctrl+alt+left";
          focus_pane_down = "ctrl+alt+down";
          focus_pane_up = "ctrl+alt+up";
          focus_pane_right = "ctrl+alt+right";
          resize_mode = ["prefix+ctrl+left" "prefix+ctrl+down" "prefix+ctrl+up" "prefix+ctrl+right"];
          resize_pane_left = "ctrl+alt+shift+left";
          resize_pane_down = "ctrl+alt+shift+down";
          resize_pane_up = "ctrl+alt+shift+up";
          resize_pane_right = "ctrl+alt+shift+right";
          rename_pane = "prefix+shift+o";
          new_tab = "prefix+c";
          rename_tab = "prefix+r";
          close_tab = "prefix+k";
          switch_tab = ["prefix+1..9" "alt+1..9"];
          previous_tab = ["prefix+p" "alt+left"];
          next_tab = ["prefix+n" "alt+right"];
          move_tab_previous = "alt+shift+left";
          move_tab_next = "alt+shift+right";
          new_workspace = "prefix+shift+c";
          rename_workspace = "prefix+shift+r";
          close_workspace = "prefix+shift+k";
          previous_workspace = ["prefix+shift+p" "alt+up"];
          next_workspace = ["prefix+shift+n" "alt+down"];
        };

        ui = {
          show_agent_labels_on_pane_borders = true;
          agent_panel_sort = "priority";
          toast.delivery = "terminal";
          pane_gaps = false;
          pane_outer_borders = false;
          pane_scrollbars = false;
          confirm_close = false;
          prompt_new_tab_name = false;
          mouse_capture = true;
          tab_bar_right = [{type = "zoom";} {type = "hostname";}];
          window_title = "{hostname}: {workspace}";
        };

        worktrees.directory = "~/Workspace/wortkrees";
      };
    };
  };
}
