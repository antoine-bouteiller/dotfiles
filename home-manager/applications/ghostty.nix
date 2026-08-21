{
  config,
  pkgs,
  lib,
  ...
}: {
  options.local.home-manager.ghostty.enable = lib.mkEnableOption "ghostty terminal";

  config = lib.mkIf config.local.home-manager.ghostty.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;
      package =
        if pkgs.stdenv.hostPlatform.isDarwin
        then null
        else pkgs.ghostty;
      settings =
        {
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
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          async-backend = "epoll";
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
