{
  mkModule,
  pkgs,
  lib,
  ...
} @ args: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  inherit (import ../../../lib/palette.nix {inherit lib;}) colors;
in
  mkModule args "local.home-manager.terminal" {
    description = "the terminal emulator: ghostty on darwin, foot on linux";
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
          # foot's default is 3.0 (ghostty's is 1.0); same ~5% trim as below.
          scrollback.multiplier = 2.85;
          key-bindings = {
            clipboard-copy = "Control+Shift+c Control+Insert XF86Copy";
            clipboard-paste = "Control+Shift+v Shift+Insert XF86Paste";
            # Shift+Insert is foot's default primary-paste; ghostty used it for the
            # clipboard, and foot rejects a combo bound to two actions.
            primary-paste = "none";
          };
        };
      };

      programs.ghostty = lib.mkIf isDarwin {
        enable = true;
        enableZshIntegration = true;
        # The cask installs the app bundle.
        package = null;
        settings = {
          font-family = "JetBrainsMono Nerd Font";
          font-style = "Regular";
          theme = lib.mkForce "ghostty";
          window-theme = "auto";
          window-padding-x = 14;
          window-padding-y = 14;
          confirm-close-surface = false;
          resize-overlay = "never";
          gtk-toolbar-style = "flat";
          cursor-style = "block";
          cursor-style-blink = false;
          shell-integration-features = "no-cursor,ssh-env";
          keybind = [
            "shift+insert=paste_from_clipboard"
            "control+insert=copy_to_clipboard"
            "shift+enter=csi:13;2u"
            "alt+shift+enter=csi:13;4u"
            "super+control+shift+alt+arrow_down=resize_split:down,100"
            "super+control+shift+alt+arrow_up=resize_split:up,100"
            "super+control+shift+alt+arrow_left=resize_split:left,100"
            "super+control+shift+alt+arrow_right=resize_split:right,100"
          ];
          mouse-scroll-multiplier = 0.95;
        };
        themes.ghostty = {
          palette = [
            "0=${colors.backgroundDark}"
            "1=${colors.red}"
            "2=${colors.green}"
            "3=${colors.yellow}"
            "4=${colors.blue}"
            "5=${colors.magenta}"
            "6=${colors.cyan}"
            "7=${colors.textMuted}"
            "8=${colors.textFaint}"
            "9=${colors.red}"
            "10=${colors.green}"
            "11=${colors.yellow}"
            "12=${colors.blue}"
            "13=${colors.magenta}"
            "14=${colors.cyan}"
            "15=${colors.text}"
          ];
          inherit (colors) background;
          foreground = colors.text;
          cursor-color = colors.text;
          cursor-text = colors.background;
          selection-background = colors.surfaceHover;
          selection-foreground = colors.text;
        };
      };
    };
  }
