{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.home-manager.aerospace;
  keymap = import ./keymap.nix;

  # Option sits where SUPER does on dell, two keys left of the spacebar. Cmd is
  # left to macOS, which already owns Cmd+W and friends.
  mod = "alt";
  chord = mods: key: lib.concatStringsSep "-" ([mod] ++ mods ++ [key]);

  commands = {
    close = "close";
    float = "layout floating tiling";
    # -n so the bind opens a new window rather than raising the running app.
    terminal = "exec-and-forget open -na Ghostty";
    browser = "exec-and-forget open -na Helium";
    growWidth = "resize width +100";
    shrinkWidth = "resize width -100";
    growHeight = "resize height +100";
    shrinkHeight = "resize height -100";
  };

  binds =
    map (
      b: lib.nameValuePair (chord (map lib.toLower (b.mods or [])) b.key) commands.${b.action}
    )
    keymap.binds
    ++ lib.concatMap (dir: [
      (lib.nameValuePair (chord [] dir) "focus ${dir}")
      (lib.nameValuePair (chord ["shift"] dir) "move ${dir}")
    ])
    keymap.directions
    ++ lib.concatLists (lib.imap1 (index: key: [
        (lib.nameValuePair (chord [] key) "workspace ${toString index}")
        (lib.nameValuePair (chord ["shift"] key) "move-node-to-workspace ${toString index}")
      ])
      keymap.workspaceKeys);
in {
  options.local.home-manager.aerospace.enable =
    lib.mkEnableOption "the AeroSpace tiling window manager";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "local.home-manager.aerospace is macOS-only; dell tiles with hyprland.";
      }
    ];

    programs.aerospace = {
      enable = true;
      # AeroSpace's own start-at-login writes a LaunchAgent outside the store.
      launchd.enable = true;

      settings = {
        # hyprland's gaps_in 5 / gaps_out 10.
        gaps = {
          inner = {
            horizontal = 5;
            vertical = 5;
          };
          outer = {
            left = 10;
            right = 10;
            top = 10;
            bottom = 10;
          };
        };

        mode.main.binding = lib.listToAttrs binds;
      };
    };
  };
}
