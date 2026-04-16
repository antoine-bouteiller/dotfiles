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

      hooksDir = "${./hooks}";
      rulesDir = "${./rules}";
      commandsDir = "${./commands}";
    };

    home.file = {
      ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
    };
  });
}
