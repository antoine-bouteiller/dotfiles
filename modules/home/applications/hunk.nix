{
  mkModule,
  inputs,
  lib,
  ...
} @ args: let
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors mix;
in
  mkModule args "local.home-manager.hunk" {
    description = "Hunk diff viewer";
    imports = [inputs.hunk.homeManagerModules.default];
    config = _: {
      programs.hunk = {
        enable = true;
        settings = {
          theme = "custom";
          custom_theme = {
            base = "github-dark-default";
            label = "Hunk";
            inherit (colors) background text;
            panel = colors.backgroundDim;
            panelAlt = colors.surface;
            border = colors.surfaceRaised;
            accent = colors.blue;
            accentMuted = colors.steelBlue;
            muted = colors.textFaint;
            addedBg = mix colors.background colors.green 0.8;
            removedBg = mix colors.background colors.red 0.8;
            movedAddedBg = mix colors.background colors.teal 0.8;
            movedRemovedBg = mix colors.background colors.orange 0.8;
            contextBg = colors.background;
            addedContentBg = mix colors.background colors.green 0.6;
            removedContentBg = mix colors.background colors.red 0.6;
            contextContentBg = colors.background;
            addedSignColor = colors.green;
            removedSignColor = colors.red;
            lineNumberBg = colors.backgroundDim;
            lineNumberFg = colors.textFaint;
            selectedHunk = colors.surfaceRaised;
            badgeAdded = colors.green;
            badgeRemoved = colors.red;
            badgeNeutral = colors.textDim;
            fileNew = colors.green;
            fileDeleted = colors.red;
            fileRenamed = colors.magenta;
            fileModified = colors.yellow;
            fileUntracked = colors.textDim;
            noteBorder = colors.magenta;
            noteBackground = colors.backgroundDim;
            noteTitleBackground = colors.surface;
            noteTitleText = colors.text;
          };
        };
      };
    };
  }
