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
  config = lib.mkIf (cfg.enable && cfg.pi.enable && isDarwin) {
    home.packages = [package];

    launchd.agents.meridian = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe package)
        ];
        EnvironmentVariables = {
          MERIDIAN_DEBUG = "1";
          MERIDIAN_TELEMETRY_PERSIST = "1";
          MERIDIAN_TELEMETRY_RETENTION_DAYS = "2";
          # Meridian's structured logger still uses its legacy provider gate.
          OPENCODE_CLAUDE_PROVIDER_DEBUG = "1";
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
