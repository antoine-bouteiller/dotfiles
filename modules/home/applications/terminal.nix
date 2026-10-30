{
  mkModule,
  pkgs,
  lib,
  ...
} @ args: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in
  mkModule args "local.home-manager.terminal" {
    description = "the terminal emulator: Rex on darwin, foot on linux";
    config = _: {
      programs.foot = lib.mkIf isLinux {
        enable = true;
        settings = {
          main = {
            font = "JetBrainsMono Nerd Font:size=11";
            pad = "14x14";
          };
          cursor = {
            style = "block";
            blink = "no";
          };
          # foot's default is 3.0, trimmed ~5%.
          scrollback.multiplier = 2.85;
          key-bindings = {
            clipboard-copy = "Control+Shift+c Control+Insert XF86Copy";
            clipboard-paste = "Control+Shift+v Shift+Insert XF86Paste";
            # Shift+Insert is foot's default primary-paste, and foot rejects a combo
            # bound to two actions.
            primary-paste = "none";
          };
        };
      };

      local.home-manager.rex = lib.mkIf isDarwin {
        enable = lib.mkDefault true;
        client.enable = lib.mkDefault true;
      };
    };
  }
