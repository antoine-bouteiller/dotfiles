{
  config,
  osConfig,
  lib,
  ...
}: {
  options.local.home-manager.zed.enable = lib.mkEnableOption "zed editor";

  config = lib.mkIf config.local.home-manager.zed.enable (let
    inherit (config.lib.file) mkOutOfStoreSymlink;
    zedDit = "${osConfig.flakePath}/home-manager/applications/zed";
  in {
    home.file = {
      ".config/zed/settings.json".source = mkOutOfStoreSymlink "${zedDit}/settings.json";
      ".config/zed/keymap.json".source = mkOutOfStoreSymlink "${zedDit}/keymap.json";
    };
  });
}
