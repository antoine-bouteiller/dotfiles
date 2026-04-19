{
  config,
  lib,
  pkgs,
  ...
}: {
  options.local.home-manager.claudeCode.enable = lib.mkEnableOption "claude code";

  config = lib.mkIf config.local.home-manager.claudeCode.enable (let
    inherit (config.lib.file) mkOutOfStoreSymlink;
    inherit (config.home) homeDirectory;
    claudeDir = "${homeDirectory}/.dotfiles/home-manager/applications/claude-code";
  in {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;

      context = "${claudeDir}/CLAUDE.md";
    };

    home.file = {
      ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
      ".claude/hooks".source = mkOutOfStoreSymlink "${claudeDir}/hooks";
      ".claude/skills".source = mkOutOfStoreSymlink "${claudeDir}/skills";
      ".claude/commands".source = mkOutOfStoreSymlink "${claudeDir}/commands";
      ".claude/rules".source = mkOutOfStoreSymlink "${claudeDir}/rules";
    };
  });
}
