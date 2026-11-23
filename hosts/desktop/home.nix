{
  config,
  lib,
  pkgs,
  inputs,
  mkUserService,
  ...
} @ args: let
  outputs = import ./outputs.nix;
  umbrielPackage = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
  umbrielGamingRulesPath = "${config.xdg.configHome}/umbriel/gaming-display.toml";
  gamingRulesPath = "${config.xdg.configHome}/niri/gaming-display.kdl";
  syncGamingDisplay = pkgs.writeShellApplication {
    name = "sync-gaming-display";
    runtimeInputs = [pkgs.niri umbrielPackage pkgs.jq pkgs.xrandr pkgs.coreutils pkgs.gnugrep pkgs.util-linux];
    text = ''
      exec 9>"$XDG_RUNTIME_DIR/sync-gaming-display.lock"
      flock 9

      if [ -S "''${UMBRIEL_SOCKET:-}" ]; then
        output=$(umbriel outputs --json | jq -er --arg tv "${outputs.tv}" --arg asus "${outputs.asus}" '
          [.[] | select(.enabled)] |
          (map(select(.config_name == $tv)) + map(select(.config_name == $asus))) | first.name')
        rules="${umbrielGamingRulesPath}"
        mkdir -p "$(dirname "$rules")"
        cat > "$rules.tmp" <<EOF
      [[window_rule]]
      match.app_id = "^steam_app_[0-9]+$"
      default_output = "$output"
      [[window_rule]]
      match.app_id = "^steam$"
      match.title = "^Steam Big Picture Mode$"
      default_output = "$output"
      EOF
        if cmp -s "$rules.tmp" "$rules"; then
          rm "$rules.tmp"
        else
          mv "$rules.tmp" "$rules"
        fi
        if [ "$(umbriel config get general.xwayland_primary_output)" != "$output" ]; then
          umbriel config set general.xwayland_primary_output "\"$output\""
        fi
        exit 0
      fi
      if [ ! -S "''${NIRI_SOCKET:-}" ]; then
        exit 0
      fi

      output=$(niri msg --json outputs | jq -er --arg tv "${outputs.tv}" --arg asus "${outputs.asus}" '
        [.[] | select(.logical != null)] |
        (map(select([.make, .model, .serial] | join(" ") == $tv)) +
         map(select([.make, .model, .serial] | join(" ") == $asus))) | first.name')

      # Niri starts this alongside Xwayland, whose socket may not be ready yet.
      for attempt in $(seq 1 20); do
        if current=$(DISPLAY=:12 xrandr --current); then
          if printf '%s\n' "$current" | grep -q "^$output connected primary "; then
            break
          fi
          if DISPLAY=:12 xrandr --output "$output" --primary; then
            break
          fi
        fi
        if [ "$attempt" -eq 20 ]; then
          exit 1
        fi
        sleep 0.25
      done

      rules="${gamingRulesPath}"
      mkdir -p "$(dirname "$rules")"
      cat > "$rules.tmp" <<EOF
      window-rule {
          match app-id="^steam_app_[0-9]+$"
          match app-id="^steam$" title="^Steam Big Picture Mode$"
          open-on-output "$output"
          open-fullscreen true
      }
      EOF
      if cmp -s "$rules.tmp" "$rules"; then
        rm "$rules.tmp"
      else
        mv "$rules.tmp" "$rules"
        niri msg action load-config-file
      fi
    '';
  };
  toggleTv = pkgs.writeShellApplication {
    name = "toggle-tv";
    runtimeInputs = [pkgs.niri umbrielPackage pkgs.jq pkgs.procps];
    text = ''
      if [ -S "''${UMBRIEL_SOCKET:-}" ]; then
        state=$(umbriel outputs --json | jq -er --arg name "${outputs.tv}" '.[] | select(.config_name == $name) | if .enabled then "off" else "on" end')
        enabled=false
        if [ "$state" = on ]; then
          enabled=true
        fi
        # Output actions bypass the geometry configured for an initially disabled output.
        umbriel config set 'output."${outputs.tv}".enabled' "$enabled"
      else
        state=$(niri msg --json outputs | jq -er --arg name "${outputs.tv}" '.[] | select([.make, .model, .serial] | join(" ") == $name) | if .logical == null then "on" else "off" end')
        niri msg output "${outputs.tv}" "$state"
      fi
      ${lib.getExe syncGamingDisplay}
      if [ "$state" = on ] && ! pgrep -u "$(id -u)" -x steam >/dev/null; then
        steam >/dev/null 2>&1 &
      fi
    '';
  };
in {
  home.stateVersion = "26.05";
  home.packages = [syncGamingDisplay];
  imports = [
    (mkUserService args "sync-gaming-display" {
      description = "Keep the gaming display synchronized after output changes";
      command = lib.getExe syncGamingDisplay;
      interval = 5;
    })
  ];

  programs.umbriel.settings = {
    general.xwayland_primary_output = outputs.asus;
    include.optional.files = [umbrielGamingRulesPath];
    output = {
      ${outputs.tv} = {
        enabled = false;
        mode = "3840x2160";
        scale = 3.0;
        position = [(-1280) 0];
      };
      ${outputs.samsung} = {
        mode = "1920x1080";
        scale = 1.0;
        position = [0 0];
      };
      ${outputs.asus} = {
        mode = "2560x1440";
        scale = 1.0;
        position = [1920 0];
        focus_at_startup = true;
      };
    };
    window_rule = lib.mkAfter [
      {
        match.app_id = "^steam_app_[0-9]+$";
        default_fullscreen = true;
      }
      {
        match = {
          app_id = "^steam$";
          title = "^Steam Big Picture Mode$";
        };
        default_fullscreen = true;
      }
    ];
    keybinds."Mod+Shift+T" = {
      action = "spawn ${lib.getExe toggleTv}";
      repeat = false;
    };
  };

  local.home-manager.desktop.extraNiriConfig = ''
    output "${outputs.tv}" {
        off
        mode "3840x2160"
        scale 3
        position x=-1280 y=0
    }
    window-rule {
        match app-id="^steam_app_[0-9]+$"
        match app-id="^steam$" title="^Steam Big Picture Mode$"
        open-on-output "${outputs.asus}"
        open-fullscreen true
    }
    include optional=true "${gamingRulesPath}"
    output "${outputs.samsung}" {
        mode "1920x1080"
        scale 1
        position x=0 y=0
    }
    output "${outputs.asus}" {
        mode "2560x1440"
        scale 1
        position x=1920 y=0
    }
  '';
  local.home-manager.desktop.extraNiriBinds = ''
    Super+Shift+T repeat=false hotkey-overlay-title="Toggle TV" { spawn "${toggleTv}/bin/toggle-tv"; }
  '';
}
