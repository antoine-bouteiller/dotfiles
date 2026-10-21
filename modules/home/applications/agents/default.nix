{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  skillFiles = import ./skills {inherit lib inputs;};
in
  mkModule args "local.home-manager.agents" {
    description = "agent CLIs";
    imports = [
      ./claude-code
      ./pi
      inputs.spec-viewer.homeManagerModules.default
    ];

    # claude-code.enable and pi.enable are declared by the sub-modules that own them.

    # Shared across every agent CLI: MCP integration, util packages and the skill tree.
    config = {cfg}: {
      programs.mcp.enable = lib.mkDefault (config.programs.mcp.servers != {});

      programs.spec-viewer.enable = lib.mkDefault true;
      programs.zsh.shellAliases.sv = "spec-viewer";

      home.packages = with pkgs; [
        # Utils
        rtk
        vtsls
      ];

      # Every agent reads ~/.agents/skills; claude wants its own copy under ~/.claude.
      home.file =
        skillFiles ".agents"
        // lib.optionalAttrs cfg.claude-code.enable (skillFiles ".claude");
    };
  }
