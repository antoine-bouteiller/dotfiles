{lib, ...}: let
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;
in {
  programs.lazygit = {
    enable = true;
    # Lazygit ignores core.pager; delta reads its options from gitconfig.
    settings.git.diffRenderers = [{command = "delta --paging=never";}];
    settings.gui.theme = {
      activeBorderColor = [colors.blue "bold"];
      inactiveBorderColor = [colors.textFaint];
      searchingActiveBorderColor = [colors.cyan "bold"];
      optionsTextColor = [colors.blue];
      selectedLineBgColor = [colors.surfaceRaised];
      inactiveViewSelectedLineBgColor = [colors.surface];
      cherryPickedCommitFgColor = [colors.background];
      cherryPickedCommitBgColor = [colors.teal];
      markedBaseCommitFgColor = [colors.background];
      markedBaseCommitBgColor = [colors.yellow];
      unstagedChangesColor = [colors.red];
      defaultFgColor = [colors.text];
    };
  };
}
