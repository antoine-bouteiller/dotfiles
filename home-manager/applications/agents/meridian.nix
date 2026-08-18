{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.home-manager.agents;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  package = inputs.meridian.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  config = lib.mkIf (cfg.enable && cfg.pi.enable) {
    home.packages = [package];

    systemd.user.services.meridian = lib.mkIf (!isDarwin) {
      Unit.Description = "Meridian agent";
      Service = {
        ExecStart = lib.getExe package;
        Environment = [
          "MERIDIAN_NO_FILE_CHANGES=1"
          "MERIDIAN_TELEMETRY_PERSIST=1"
          "MERIDIAN_TELEMETRY_RETENTION_DAYS=2"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };

    launchd.agents.meridian = lib.mkIf isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe package)
        ];
        EnvironmentVariables = {
          MERIDIAN_NO_FILE_CHANGES = "1";
          MERIDIAN_TELEMETRY_PERSIST = "1";
          MERIDIAN_TELEMETRY_RETENTION_DAYS = "2";
        };
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        RunAtLoad = true;
        ProcessType = "Background";
        ThrottleInterval = 5;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/meridian.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/meridian.err";
      };
    };
  };
}
