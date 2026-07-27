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
