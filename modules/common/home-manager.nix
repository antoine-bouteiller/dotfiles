{
  config,
  host,
  inputs,
  globals,
  lib,
  mkModule,
  pkgs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
    users.${host.user} = import (config.local.hostDir + "/home.nix");
    sharedModules = [
      ../home
      ({
        osConfig,
        lib,
        ...
      }: {
        local.home-manager.sourcePath = lib.mkDefault osConfig.flakePath;
      })
      {
        home.enableNixpkgsReleaseCheck = false;
      }
    ];
    extraSpecialArgs = {inherit inputs globals host mkModule;};
  };
}
