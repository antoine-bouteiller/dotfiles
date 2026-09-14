# Run: nix eval --impure --json --file tests/engram-service.nix
let
  flake = builtins.getFlake (toString ./..);
  inherit (flake.inputs.nixpkgs) lib;
  home = "/tmp/engram-service-test";
  configFor = system: agentsEnabled: engramEnabled: piEnabled:
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = flake.inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        inputs = flake.inputs // {self = flake;};
        mkModule = import ../lib/module.nix lib;
      };
      modules = [
        ../modules/home/applications/agents/engram
        {
          options.local.home-manager.agents = {
            enable = lib.mkEnableOption "agents";
            pi.enable = lib.mkEnableOption "Pi";
          };
          config = {
            local.home-manager.agents = {
              enable = agentsEnabled;
              engram.enable = engramEnabled;
              pi.enable = piEnabled;
            };
            home = {
              username = "engram-test";
              homeDirectory = home;
              stateVersion = "25.11";
            };
          };
        }
      ];
    }).config;
  check = system: let
    cfg = configFor system true true true;
    disabled = configFor system true false true;
    agentsDisabled = configFor system false true true;
    piDisabled = configFor system true true false;
    extensionPath = ".pi/agent/extensions/engram";
    darwin = system == "aarch64-darwin";
    exe = lib.getExe flake.packages.${system}.engram;
  in
    assert !(disabled.systemd.user.services ? engram) && !(disabled.launchd.agents ? engram);
    assert !(agentsDisabled.systemd.user.services ? engram) && !(agentsDisabled.launchd.agents ? engram);
    assert !(cfg.systemd.user.services ? engram-sync) && !(cfg.launchd.agents ? engram-sync);
    assert cfg.programs.mcp.servers.engram.args == ["mcp" "--tools=agent"];
    assert cfg.home.file.${extensionPath}.source == flake.packages.${system}.engram.piExtension;
    assert !(disabled.home.file ? ${extensionPath}) && !(agentsDisabled.home.file ? ${extensionPath});
    assert !(piDisabled.home.file ? ${extensionPath});
    assert !(lib.any (lib.hasPrefix "npm:gentle-engram") (lib.importJSON ../agents/pi/settings.json).packages);
      if darwin
      then let
        service = cfg.launchd.agents.engram;
      in
        assert !(cfg.systemd.user.services ? engram);
        assert service.enable && service.config.RunAtLoad && service.config.KeepAlive;
        assert service.config.ProgramArguments == [exe "serve"];
        assert service.config.WorkingDirectory == home;
        assert service.config.EnvironmentVariables
        == {
          ENGRAM_DATA_DIR = "${home}/.engram";
          ENGRAM_NO_UPDATE_CHECK = "1";
        }; true
      else let
        service = cfg.systemd.user.services.engram;
      in
        assert !(cfg.launchd.agents ? engram);
        assert service.Service.ExecStart == ["${exe} serve"];
        assert service.Service.Restart == "always" && service.Service.RestartSec == 3;
        assert service.Service.WorkingDirectory == home;
        assert service.Service.Environment == ["ENGRAM_DATA_DIR=${home}/.engram" "ENGRAM_NO_UPDATE_CHECK=1"];
        assert service.Install.WantedBy == ["default.target"]; true;
in
  lib.genAttrs ["aarch64-darwin" "x86_64-linux"] check
