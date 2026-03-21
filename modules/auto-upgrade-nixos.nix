{
  globals,
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.autoUpgrade;
  flakePath = cfg.flakePath;
in {
  options.autoUpgrade = {
    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${globals.user}/.dotfiles/nixos-config";
      description = "Path to the flake directory";
    };
    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow automatic reboots after upgrade";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "Sun *-*-* 01:00:00";
      description = "Systemd calendar schedule for auto-upgrade";
    };
  };

  config = {
    # Pull latest flake.lock before rebuild
    systemd.services.flake-pull = {
      stopIfChanged = false;
      restartIfChanged = false;

      unitConfig = {
        Description = "Pull latest flake.lock from remote";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      serviceConfig = {
        WorkingDirectory = flakePath;

        ExecStart = pkgs.writeShellScript "flake-pull-script" ''
          ${pkgs.git}/bin/git pull --ff-only origin main
        '';
        Restart = "on-failure";
        RestartSec = "30";
        Type = "oneshot";
      };

      before = ["nixos-upgrade.service"];
      path = [pkgs.git];
    };

    system.autoUpgrade =
      {
        enable = true;
        dates = cfg.schedule;
        flake = flakePath;
        flags = ["-L"];
        allowReboot = cfg.allowReboot;
      }
      // lib.optionalAttrs cfg.allowReboot {
        rebootWindow = {
          lower = "01:00";
          upper = "03:00";
        };
      };

    systemd.services.nixos-upgrade = {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "120";
        MemoryMax = "2G";
        Nice = 19;
        IOSchedulingClass = "idle";
      };
      unitConfig = {
        StartLimitIntervalSec = 600;
        StartLimitBurst = 2;
      };
      after = ["flake-pull.service"];
      wants = ["flake-pull.service"];
      path = [pkgs.host];
    };
  };
}
