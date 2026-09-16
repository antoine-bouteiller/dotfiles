{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.engram;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
  mkModule args "local.home-manager.agents.engram" {
    description = "Engram persistent agent memory";

    options.server.enable = lib.mkEnableOption "the local Engram server" // {default = true;};

    config = {cfg}:
      lib.mkIf agents.enable {
        home.packages = lib.optional cfg.server.enable package;
        local.home-manager.agents.pi.env.ENGRAM_URL = lib.mkDefault "http://127.0.0.1:7437";
        # Pi supplies its core runtime dependencies; keep all companion files.
        home.file.".pi/agent/extensions/engram" = lib.mkIf agents.pi.enable {
          source = package.piExtension;
        };

        systemd.user.services.engram = lib.mkIf (cfg.server.enable && !isDarwin) {
          Unit = {
            Description = "Engram Memory Server";
            After = ["network.target"];
          };
          Service = {
            ExecStart = "${lib.getExe package} serve";
            WorkingDirectory = config.home.homeDirectory;
            Environment = [
              "ENGRAM_DATA_DIR=${config.home.homeDirectory}/.engram"
              "ENGRAM_NO_UPDATE_CHECK=1"
            ];
            Restart = "always";
            RestartSec = 3;
            UMask = "0077";
          };
          Install.WantedBy = ["default.target"];
        };

        launchd.agents.engram = lib.mkIf (cfg.server.enable && isDarwin) {
          enable = true;
          config = {
            ProgramArguments = [(lib.getExe package) "serve"];
            WorkingDirectory = config.home.homeDirectory;
            EnvironmentVariables = {
              ENGRAM_DATA_DIR = "${config.home.homeDirectory}/.engram";
              ENGRAM_NO_UPDATE_CHECK = "1";
            };
            RunAtLoad = true;
            KeepAlive = true;
            ProcessType = "Background";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/engram.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/engram.err";
          };
        };
      };
  }
