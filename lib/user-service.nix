# Declares a Home Manager user service on systemd (Linux) and launchd (macOS).
# Without `interval`, it runs at login and restarts on failure; with it, it runs
# at login and every `interval` seconds.
#
#   {mkUserService, ...} @ args:
#     mkUserService args "meridian" {
#       description = "Meridian agent";
#       command = lib.getExe pkg;
#     }
lib: args: name: {
  description,
  command,
  environment ? {},
  interval ? null,
}: let
  inherit (args) config pkgs;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  periodic = interval != null;
  launchdProgram = import ./launchd-program.nix {inherit lib pkgs;};
in {
  systemd.user = lib.mkIf (!isDarwin) {
    services.${name} =
      {
        Unit.Description = description;
        Service =
          {
            ExecStart = command;
            Environment = lib.mapAttrsToList (n: v: "${n}=${v}") environment;
          }
          // (
            if periodic
            then {Type = "oneshot";}
            else {
              Restart = "on-failure";
              RestartSec = 5;
            }
          );
      }
      // lib.optionalAttrs (!periodic) {Install.WantedBy = ["default.target"];};

    timers = lib.optionalAttrs periodic {
      ${name} = {
        Unit.Description = description;
        Timer = {
          OnStartupSec = 0;
          OnUnitActiveSec = interval;
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };

  launchd.agents.${name} = lib.mkIf isDarwin {
    enable = true;
    # Shows the agent by name instead of "sh" in Login Items.
    waitForNixStore = false;
    config =
      {
        ProgramArguments = launchdProgram {
          inherit name;
          logDir = "${config.home.homeDirectory}/Library/Logs";
          command = [command];
        };
        EnvironmentVariables = environment;
        RunAtLoad = true;
        ProcessType = "Background";
      }
      // (
        if periodic
        then {StartInterval = interval;}
        else {
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ThrottleInterval = 5;
        }
      );
  };
}
