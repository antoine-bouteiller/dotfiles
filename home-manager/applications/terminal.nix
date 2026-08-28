{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in {
  options.local.home-manager.terminal.enable = lib.mkEnableOption "the terminal emulator: ghostty on darwin, foot on linux";

  config = lib.mkIf config.local.home-manager.terminal.enable {
    programs.foot = lib.mkIf isLinux {
      enable = true;
      settings = {
        main = {
          # ghostty ships its own JetBrains Mono; foot resolves the system one.
          font = "JetBrainsMono Nerd Font:size=11";
          pad = "14x14";
        };
        cursor = {
          style = "block";
          blink = "no";
        };
        scrollback.multiplier = 0.95;
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
        font-style = "Regular";
        theme = lib.mkForce "light:Catppuccin Latte,dark:Catppuccin Mocha";
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
      themes."JetBrains Islands Dark" = {
        palette = [
          "0=#191a1c"
          "1=#f75464"
          "2=#6aab73"
          "3=#cf8e6d"
          "4=#56a8f5"
          "5=#c77dbb"
          "6=#2aacb8"
          "7=#bcbec4"
          "8=#7a7e85"
          "9=#f57e84"
          "10=#6db083"
          "11=#f0ac81"
          "12=#548af7"
          "13=#b189f5"
          "14=#16baac"
          "15=#ffffff"
        ];
        background = "#191a1c";
        foreground = "#bcbec4";
        cursor-color = "#ced0d6";
        cursor-text = "#191a1c";
        selection-background = "#2a4371";
        selection-foreground = "#d1d3d8";
      };
    };
  };
}
