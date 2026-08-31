{
  mkModule,
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  skillFiles = import ./skills.nix {
    inherit lib inputs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
    agentsDir = "${osConfig.flakePath}/agents";
  };
in
  mkModule args "local.home-manager.agents" {
    description = "agent CLIs";
    imports = [
      ./claude-code.nix
      ./pi.nix
      ./meridian.nix
    ];

    options = {
      mcpServers = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = {};
        description = ''
          MCP servers attrset, forwarded to the shared `programs.mcp.servers`.
          Every agent CLI with enableMcpIntegration = true (claude-code today;
          codex/antigravity-cli later) picks these up.
        '';
      };
    };
    # claude-code.enable and pi.enable are declared by the sub-modules that own them.

    # Shared across every agent CLI: MCP servers, util packages and the skill tree.
    config = {cfg}: {
      programs.mcp = {
        enable = cfg.mcpServers != {};
        servers = cfg.mcpServers;
      };

      home.packages = with pkgs; [
        # Utils
        customPkgs.comment-checker
        (rtk.overrideAttrs (_: {doCheck = false;}))
        vtsls
        jdt-language-server
      ];

      # Every agent reads ~/.agents/skills; claude wants its own copy under ~/.claude.
      home.file =
        skillFiles ".agents"
        // lib.optionalAttrs cfg.claude-code.enable (skillFiles ".claude");
    };
  }
