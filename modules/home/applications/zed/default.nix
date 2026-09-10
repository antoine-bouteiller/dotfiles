{
  mkModule,
  config,
  pkgs,
  lib,
  inputs,
  ...
} @ args:
mkModule args "local.home-manager.zed" {
  description = "zed editor";
  config = _: let
    inherit (config.lib.file) mkOutOfStoreSymlink;
    customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
    zedDit = "${config.local.home-manager.sourcePath}/modules/home/applications/zed";
  in {
    # settings.json points the jdtls extension at go-jls; Darwin gets the editor from Homebrew.
    home.packages = [customPkgs.go-jls] ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [pkgs.zed-editor];

    programs.zsh.shellAliases = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
      zed = "zeditor";
    };

    home.file = {
      ".config/zed/settings.json".source = mkOutOfStoreSymlink "${zedDit}/settings.json";
      ".config/zed/keymap.json".source = mkOutOfStoreSymlink "${zedDit}/keymap.json";
    };
  };
}
