{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # 1. Alias the config path for cleaner access
  cfg = config.local.home-manager.claudeCode;

  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  claudeDir = "${osConfig.flakePath}/home-manager/applications/claude-code";
in {
  options.local.home-manager.claudeCode = {
    enable = lib.mkEnableOption "claude code";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code
      # Agents
      customPkgs.comment-checker
      customPkgs.rtk
      customPkgs._1mcp
    ];

    home.file = builtins.listToAttrs (map (name: {
        name = ".claude/${name}";
        value = {source = mkOutOfStoreSymlink "${claudeDir}/${name}";};
      }) [
        "CLAUDE.md"
        "settings.json"
        "hooks"
        "skills"
        "commands"
        "rules"
      ]);
  };
}
