{lib, ...}: let
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;
in {
  programs.lazygit = {
    enable = true;
    settings.gui.theme = {
      activeBorderColor = [colors.blue "bold"];
      inactiveBorderColor = [colors.surfaceRaised];
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
