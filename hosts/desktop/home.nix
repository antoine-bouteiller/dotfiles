{pkgs, ...}: let
  tvName = "Samsung Electric Company SAMSUNG 0x01000E00";
  toggleTv = pkgs.writeShellApplication {
    name = "toggle-tv";
    runtimeInputs = [pkgs.niri pkgs.jq pkgs.procps];
    text = ''
      state=$(niri msg --json outputs | jq -er --arg name "${tvName}" '.[] | select([.make, .model, .serial] | join(" ") == $name) | if .logical == null then "on" else "off" end')
      niri msg output "${tvName}" "$state"
      if [ "$state" = on ] && ! pgrep -u "$(id -u)" -x steam >/dev/null; then
        steam >/dev/null 2>&1 &
      fi
    '';
  };
in {
  home.stateVersion = "26.05";

  local.home-manager.desktop.extraNiriConfig = ''
    output "${tvName}" {
        off
        mode "3840x2160"
        scale 3
        position x=-1280 y=0
    }
    window-rule {
        match app-id="^steam$" title="^Steam Big Picture Mode$"
        open-on-output "${tvName}"
        open-fullscreen true
    }
    output "Samsung Electric Company S24D330 0x5A5A5131" {
        mode "1920x1080"
        scale 1
        position x=0 y=0
    }
    output "ASUSTek COMPUTER INC VG27A LCLMQS128654" {
        mode "2560x1440"
        scale 1
        position x=1920 y=0
    }
  '';
  local.home-manager.desktop.extraNiriBinds = ''
    Super+Shift+T repeat=false hotkey-overlay-title="Toggle TV" { spawn "${toggleTv}/bin/toggle-tv"; }
  '';
}
