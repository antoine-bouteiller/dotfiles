{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.paneru;
  keymap = import ./keymap.nix;

  # Option sits where SUPER does on dell, two keys left of the spacebar. Cmd is
  # left to macOS, which already owns Cmd+W and friends.
  mod = "alt";
  chord = mods: key: "${lib.concatStringsSep " + " ([mod] ++ mods)} - ${key}";

  commands = {
    float = "window_manage";
    # paneru resizes by cycling preset column widths rather than by pixels.
    growWidth = "window_grow";
    shrinkWidth = "window_shrink";
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

  binds =
    map (
      b: lib.nameValuePair commands.${b.action} (chord (map lib.toLower (b.mods or [])) b.key)
    )
    keymap.binds
    ++ lib.concatMap (dir: [
      (lib.nameValuePair "window_focus_${directionCommands.${dir}}" (chord [] directionKeys.${dir}))
      (lib.nameValuePair "window_swap_${directionCommands.${dir}}" (chord ["shift"] directionKeys.${dir}))
    ])
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: key: [
        (lib.nameValuePair "window_virtualnum_${toString index}" (chord [] key))
        (lib.nameValuePair "window_virtualmovenum_${toString index}" (chord ["shift"] key))
      ])
      keymap.workspaceKeys);
in {
  # The module is inert until enabled, and it asserts macOS itself: dell tiles
  # with niri and never sets the toggle.
  imports = [inputs.paneru.homeModules.paneru];

  options.local.home-manager.paneru.enable =
    lib.mkEnableOption "the Paneru sliding window manager";

  config = lib.mkIf cfg.enable {
    services.paneru = {
      enable = true;

      settings = {
        # paneru creates one virtual workspace per space; the shared keymap binds ten.
        default_workspaces = builtins.length keymap.workspaceKeys;

        # niri's gaps 10, at the only place paneru has gaps: the screen edges.
        padding = {
          top = 10;
          bottom = 10;
          left = 10;
          right = 10;
        };

        bindings = lib.listToAttrs binds;
      };
    };
  };
}
