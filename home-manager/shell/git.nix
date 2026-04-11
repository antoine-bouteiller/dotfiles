{
  globals,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    ignores = [
      # Editor
      "*.swp"
      "*~"
      ".vscode/"
      ".idea/"
      ".zed/"

      # OS
      ".DS_Store"
      "Thumbs.db"

      # Nix
      "result"
      "result-*"

      # Direnv
      ".direnv/"

      # Node
      "node_modules/"

      # Claude
      ".claude/settings.local.json"
    ];
    lfs = {
      enable = true;
    };
    settings = {
      user = {
        name = globals.name;
        email = lib.mkDefault globals.email;
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
    };
  };
}
