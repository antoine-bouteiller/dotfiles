{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  cfg = agents.engram;
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.engram;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  syncRepo = "${config.home.homeDirectory}/.local/share/engram-sync";
  sync = pkgs.writeShellApplication {
    name = "engram-git-sync";
    runtimeInputs = [package pkgs.git pkgs.openssh pkgs.coreutils];
    text = ''
      umask 077
      export ENGRAM_NO_UPDATE_CHECK=1
      exec ${lib.getExe pkgs.nushell} --no-config-file ${./sync.nu} "$@"
    '';
  };
  syncArgs = [
    (lib.getExe sync)
    cfg.gitRemote
    syncRepo
  ];
in
  mkModule args "local.home-manager.agents.engram" {
    description = "Engram persistent agent memory";

    options.gitRemote = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      example = "git@example.org:me/agent-memory.git";
      description = ''
        Dedicated private Git remote for all Engram projects. When set, export,
        merge, import and push every 15 minutes. Null keeps memory local only.
        Use SSH or a credential helper, never credentials embedded in the URL.
        Merge conflicts stop synchronization for manual resolution.
        Git exports are not full backups: upstream does not propagate hard
        deletes, prompt deletions or all updates to existing session metadata.
      '';
    };

    config = _:
      lib.mkIf agents.enable {
        home.packages = [package] ++ lib.optional (cfg.gitRemote != null) sync;
        home.sessionVariables.ENGRAM_NO_UPDATE_CHECK = "1";
        # Pi supplies its core runtime dependencies; keep all companion files.
        home.file.".pi/agent/extensions/engram" = lib.mkIf agents.pi.enable {
          source = package.piExtension;
        };

        programs.mcp.servers.engram = {
          command = lib.getExe package;
          args = ["mcp" "--tools=agent"];
          env.ENGRAM_NO_UPDATE_CHECK = "1";
        };

        systemd.user.services.engram = lib.mkIf (!isDarwin) {
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

        launchd.agents.engram = lib.mkIf isDarwin {
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

        systemd.user.services.engram-sync = lib.mkIf (!isDarwin && cfg.gitRemote != null) {
          Unit.Description = "Sync Engram memories through Git";
          Service = {
            Type = "oneshot";
            ExecStart = lib.escapeShellArgs syncArgs;
            UMask = "0077";
          };
        };
        systemd.user.timers.engram-sync = lib.mkIf (!isDarwin && cfg.gitRemote != null) {
          Unit.Description = "Sync Engram memories every 15 minutes";
          Timer = {
            OnStartupSec = "1m";
            OnUnitActiveSec = "15m";
          };
          Install.WantedBy = ["timers.target"];
        };

        launchd.agents.engram-sync = lib.mkIf (isDarwin && cfg.gitRemote != null) {
          enable = true;
          config = {
            ProgramArguments = syncArgs;
            StartInterval = 900;
            RunAtLoad = true;
            ProcessType = "Background";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/engram-sync.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/engram-sync.err";
          };
        };
      };
  }
