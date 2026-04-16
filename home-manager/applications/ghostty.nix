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
        if pkgs.stdenv.isDarwin
        then null
        else pkgs.ghostty;
      settings = {
        keybind = "shift+enter=text:\\x1b\\r";
        shell-integration-features = true;
      };
    };
  };
}
