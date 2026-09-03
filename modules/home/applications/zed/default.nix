{
  mkModule,
  config,
  osConfig,
  pkgs,
  lib,
  ...
} @ args:
mkModule args "local.home-manager.zed" {
  description = "zed editor";
  config = _: let
    inherit (config.lib.file) mkOutOfStoreSymlink;
    zedDit = "${osConfig.flakePath}/modules/home/applications/zed";
  in {
    home.packages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [pkgs.zed-editor];

    programs.zsh.shellAliases = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
      zed = "zeditor";
    };

    home.file = {
      ".config/zed/settings.json".source = mkOutOfStoreSymlink "${zedDit}/settings.json";
      ".config/zed/keymap.json".source = mkOutOfStoreSymlink "${zedDit}/keymap.json";
    };
  };
}
