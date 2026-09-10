{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  skillFiles = import ./skills.nix {
    inherit lib inputs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
    agentsDir = "${config.local.home-manager.sourcePath}/agents";
  };
in
  mkModule args "local.home-manager.agents" {
    description = "agent CLIs";
    imports = [
      ./claude-code.nix
      ./pi.nix
      ./meridian.nix
    ];

    # claude-code.enable and pi.enable are declared by the sub-modules that own them.

    # Shared across every agent CLI: MCP integration, util packages and the skill tree.
    config = {cfg}: {
      programs.mcp.enable = lib.mkDefault (config.programs.mcp.servers != {});

      home.packages = with pkgs; [
        # Utils
        customPkgs.comment-checker
        rtk
        vtsls
      ];

      # Every agent reads ~/.agents/skills; claude wants its own copy under ~/.claude.
      home.file =
        skillFiles ".agents"
        // lib.optionalAttrs cfg.claude-code.enable (skillFiles ".claude");
    };
  }
