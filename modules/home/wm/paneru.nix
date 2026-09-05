{
  mkModule,
  lib,
  inputs,
  ...
} @ args: let
  keymap = import ./keymap.nix;
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;

  # Option sits where SUPER does on dell, two keys left of the spacebar. Cmd is
  # left to macOS, which already owns Cmd+W and friends. Ctrl joins it because
  # the Apple fr layout puts a character on every alt+<key>: alt+shift+l is a
  # pipe, alt+arrow is word-wise motion. Ctrl+alt types nothing at all, and niri
  # carries the same Ctrl so the chords match on both hosts.
  mod = "ctrl + alt";
  chord = mods: key: "${lib.concatStringsSep " + " ([mod] ++ mods)} - ${keymap.appleFrench.${key} or key}";

  commands = {
    float = "window_manage";
    # Aliases of window_resize, which cycles the preset column widths.
    cycleWidth = "window_grow";
    cycleWidthBack = "window_shrink";
  };
  # niri's columns and rows are paneru's compass directions.
  directionCommands = {
    left = "west";
    right = "east";
    up = "north";
    down = "south";
  };
  directionKeys = {
    left = "leftarrow";
    right = "rightarrow";
    up = "uparrow";
    down = "downarrow";
  };
  # Each direction answers to its arrow and to the shared vim-style letter;
  # paneru takes a list of chords per command.
  keysFor = dir: [directionKeys.${dir} keymap.directionLetters.${dir}];

  binds =
    map (
      b: lib.nameValuePair commands.${b.action} (chord (map lib.toLower (b.mods or [])) b.key)
    )
    keymap.binds
    ++ lib.concatMap (dir: [
      (lib.nameValuePair "window_focus_${directionCommands.${dir}}" (map (chord []) (keysFor dir)))
      (lib.nameValuePair "window_swap_${directionCommands.${dir}}" (map (chord ["shift"]) (keysFor dir)))
    ])
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: key: [
        (lib.nameValuePair "window_virtualnum_${toString index}" (chord [] key))
        (lib.nameValuePair "window_virtualmovenum_${toString index}" (chord ["shift"] key))
      ])
      keymap.workspaceKeys);
in
  # The module is inert until enabled, and it asserts macOS itself: dell tiles
  # with niri and never sets the toggle.
  mkModule args "local.home-manager.paneru" {
    description = "the Paneru sliding window manager";
    imports = [inputs.paneru.homeModules.paneru];
    config = _: {
      services.paneru = {
        enable = true;

        settings = {
          # paneru creates one virtual workspace per space; the shared keymap binds ten.
          default_workspaces = builtins.length keymap.workspaceKeys;

          options = {
            # paneru warps focus to whatever the pointer sits on, so a keyboard
            # focus move that slides another window under the cursor is undone
            # immediately. niri doesn't do this either.
            focus_follows_mouse = false;
            # Unset means "instant": paneru substitutes an absurdly high speed.
            animation_speed = 12;
            # Row swaps snap: the slide-in only delays the window you asked for.
            virtual_workspace_animations = false;
            preset_column_widths = keymap.presetWidths;
          };

          swipe = {
            # Continuous lets the strip scroll past its own ends, which is how
            # windows end up half off the left edge; snap to the edge instead.
            continuous = false;

            # Three fingers sideways scroll the strip, as in niri; vertical
            # switches virtual workspace rows, which the number chords also
            # reach. macOS Mission Control still sees the vertical swipe, so
            # unbind it in System Settings if the two fight.
            gesture = {
              fingers_count = 3;
              direction = "Natural";
              vertical = true;
            };
          };

          # niri's gaps 10: paneru splits them between the screen edges and a
          # per-window margin, which is the only inter-window gap it has.
          padding = {
            top = 5;
            bottom = 5;
            left = 5;
            right = 5;
          };

          # niri's 2px mauve border, which macOS has no equivalent of.
          decorations.active.border = {
            enabled = true;
            color = colors.mauve;
            width = 2.0;
          };

          windows.tiled = {
            title = ".*";
            horizontal_padding = 5;
            vertical_padding = 5;
          };

          bindings = lib.listToAttrs binds;
        };
      };
    };
  }
