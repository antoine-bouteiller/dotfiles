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

        ui = {
          show_agent_labels_on_pane_borders = true;
          agent_panel_sort = "priority";
          toast = {
            delivery = "terminal";
          };
        };

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

        worktrees = {
          directory = "~/Workspace/wortkrees";
        };
      };
    };
  };
}
