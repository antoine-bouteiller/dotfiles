{
  mkModule,
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  claudeDir = "${osConfig.flakePath}/agents/claude-code";

  topLevelFiles = [
    "CLAUDE.md"
    "settings.json"
    "hooks"
    "agents"
    ".lsp.json"
  ];
in
  mkModule args "local.home-manager.agents.claude-code" {
    description = "claude-code, with its config and ~/.claude/skills";

    # The native HM module owns the package (wrapped with --plugin-dir for MCP).
    # Everything hand-edited stays on mkOutOfStoreSymlink: edit-and-go, no rebuild.
    config = _:
      lib.mkIf agents.enable {
        programs.claude-code = {
          enable = true;
          package = customPkgs.claude-code;
          enableMcpIntegration = true;
        };

        home.file =
          builtins.listToAttrs (map (name: {
              name = ".claude/${name}";
              value.source = mkOutOfStoreSymlink "${claudeDir}/${name}";
            })
            topLevelFiles)
          // {
            ".config/ccstatusline/settings.json".source =
              mkOutOfStoreSymlink "${claudeDir}/ccstatusline.json";
          };
      };
  }
