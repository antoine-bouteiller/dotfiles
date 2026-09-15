{
  lib,
  pkgs,
  ...
}: let
  displaySwitch = pkgs.writeShellApplication {
    name = "desktop-display-switch";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.niri pkgs.systemd];
    text = builtins.readFile ./display-switch.sh;
  };
in {
  xdg.configFile = {
    "OpenRGB/OpenRGB.json".source = ./openrgb/OpenRGB.json;
    "OpenRGB/Purple.orp".source = ./openrgb/Purple.orp;
    "OpenRGB/Stopped.orp".source = ./openrgb/Stopped.orp;
  };

  systemd.user.services.desktop-display-switch = {
    Unit = {
      Description = "Select DP-1 settings from the connected Samsung display's EDID";
      After = ["niri.service"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = lib.getExe displaySwitch;
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  home.stateVersion = "26.05";

  local.home-manager.desktop.extraNiriConfig = ''
    output "DP-1" {
        mode "1920x1080@60.000"
        scale 1
        position x=0 y=180
    }
    output "DP-3" {
        mode "2560x1440@143.972"
        scale 1
        position x=1920 y=0
    }
  '';
}
