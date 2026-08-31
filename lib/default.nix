{
  inputs,
  globals,
  self,
}: let
  inherit
    (inputs)
    nixpkgs
    darwin
    home-manager
    sops-nix
    ;
  mkModule = import ./module.nix nixpkgs.lib;
  commonSpecialArgs = {inherit inputs globals mkModule;};
  # Home-manager modules don't inherit the system specialArgs.
  hmSpecialArgs = {home-manager.extraSpecialArgs = {inherit mkModule;};};
in {
  mkDarwinHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }:
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.darwinModules.home-manager
          hmSpecialArgs
          {
            networking.hostName = hostname;
          }
          (self + "/hosts/${name}")
        ]
        ++ extraModules;
    };

  mkNixosHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.nixosModules.home-manager
          hmSpecialArgs
          sops-nix.nixosModules.sops
          {networking.hostName = nixpkgs.lib.mkDefault hostname;}
          (self + "/hosts/${name}")
        ]
        ++ extraModules;
    };
}
