{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.agents;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  skillFiles = import ./skills.nix {
    inherit lib inputs;
    inherit (config.lib.file) mkOutOfStoreSymlink;
    agentsDir = "${osConfig.flakePath}/agents";
  };
in {
  imports = [
    ./claude-code.nix
    ./pi.nix
    ./meridian.nix
  ];

  options.local.home-manager.agents = {
    enable = lib.mkEnableOption "agent CLIs";

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = ''
        MCP servers attrset, forwarded to the shared `programs.mcp.servers`.
        Every agent CLI with enableMcpIntegration = true (claude-code today;
        codex/antigravity-cli later) picks these up.
      '';
    };

    claude-code.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deploy claude-code with its config and ~/.claude/skills.";
    };

    pi.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deploy pi's settings.json and hand-vendored extensions (edit-and-go symlinks).";
    };
  };

  # Shared across every agent CLI: MCP servers, util packages and the skill tree.
  config = lib.mkIf cfg.enable {
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
