{
  mkModule,
  inputs,
  pkgs,
  config,
  lib,
  ...
} @ args: let
  package = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;

  # Saved SSH machines matching sopsAgeKeyHosts get the age key through `SendEnv SOPS_AGE_KEY`;
  # sops reads SOPS_AGE_KEY before SOPS_AGE_KEY_FILE, so pi/runenv on the VM just work.
  # Exported here, not in the shell, so the key only lives in herdr's process tree.
  herdrWrapped = pkgs.writeShellScriptBin "herdr" ''
    key_file="''${SOPS_AGE_KEY_FILE:-${config.home.homeDirectory}/.config/sops/age/keys.txt}"
    if [[ -z "''${SOPS_AGE_KEY:-}" && -r "$key_file" ]]; then
      export SOPS_AGE_KEY="$(<"$key_file")"
    fi
    exec ${lib.getExe package} "$@"
  '';

  # Dev tab: pi on the left, two empty shells stacked on the right.
  herdrDev = pkgs.writeShellApplication {
    name = "herdr-dev";
    runtimeInputs = [package pkgs.jq];
    text = ''
      left=$(herdr tab create --label Dev --focus ''${HERDR_WORKSPACE_ID:+--workspace "$HERDR_WORKSPACE_ID"} | jq -r .result.root_pane.pane_id)
      right=$(herdr pane split "$left" --direction right --ratio 0.5 --no-focus | jq -r .result.pane.pane_id)
      herdr pane split "$right" --direction down --ratio 0.85 --no-focus >/dev/null
      herdr pane run "$left" pi >/dev/null
    '';
  };

  herdrNvim = pkgs.writeShellApplication {
    name = "herdr-nvim";
    runtimeInputs = [package pkgs.jq];
    text = ''
      pane=$(herdr tab create --label NeoVim --focus ''${HERDR_WORKSPACE_ID:+--workspace "$HERDR_WORKSPACE_ID"} | jq -r .result.root_pane.pane_id)
      herdr pane rename "$pane" NeoVim >/dev/null
      herdr pane run "$pane" nvim . >/dev/null
    '';
  };
in
  mkModule args "local.home-manager.herdr" {
    description = "HerdR terminal session manager";

    options.sopsAgeKeyHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "ssh host patterns whose herdr machines receive the local sops age key as SOPS_AGE_KEY (sshd needs AcceptEnv SOPS_AGE_KEY).";
    };

    config = {cfg}: {
      home.packages =
        [
          (
            if cfg.sopsAgeKeyHosts == []
            then package
            else herdrWrapped
          )
          herdrDev
          herdrNvim
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.isLinux && config.local.home-manager.desktop.enable) [pkgs.wl-clipboard];
      programs.ssh.settings = lib.genAttrs cfg.sopsAgeKeyHosts (_: {SendEnv = ["SOPS_AGE_KEY"];});
      xdg.configFile."herdr/config.toml" = {
        force = true;
        source = (pkgs.formats.toml {}).generate "herdr-config" {
          onboarding = false;
          theme = {
            name = "terminal";
            auto_switch = false;
            custom = {
              inherit (colors) text green yellow red blue teal;
              accent = colors.blue;
              panel_bg = colors.background;
              sidebar_bg = colors.background;
              active_row_bg = colors.surface;
              selection_bg = colors.surfaceRaised;
              surface0 = colors.surface;
              surface1 = colors.surfaceRaised;
              surface_dim = colors.backgroundDim;
              overlay0 = colors.textFaint;
              overlay1 = colors.textDim;
              subtext0 = colors.textMuted;
              mauve = colors.magenta;
              peach = colors.orange;
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
            previous_tab = ["prefix+p" "prefix+left"];
            next_tab = ["prefix+n" "prefix+right"];
            move_tab_previous = "alt+shift+left";
            move_tab_next = "alt+shift+right";
            new_workspace = "prefix+shift+c";
            rename_workspace = "prefix+shift+r";
            close_workspace = "prefix+shift+k";
            previous_workspace = ["prefix+shift+p" "prefix+up"];
            next_workspace = ["prefix+shift+n" "prefix+down"];
            command = [
              {
                key = "prefix+shift+d";
                type = "shell";
                command = lib.getExe herdrDev;
              }
              {
                key = "prefix+shift+v";
                type = "shell";
                command = lib.getExe herdrNvim;
              }
            ];
          };

          ui = {
            show_agent_labels_on_pane_borders = true;
            agent_panel_sort = "priority";
            toast.delivery = "terminal";
            sound.enabled = false;
            pane_borders = "always";
            pane_gaps = true;
            pane_outer_borders = true;
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
