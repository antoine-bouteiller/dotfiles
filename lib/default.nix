{
  inputs,
  globals,
  self,
}: let
  inherit (inputs) nixpkgs darwin home-manager sops-nix;
  commonSpecialArgs = {inherit inputs globals;};
in {
  mkDarwinHost = {
    hostname,
    system,
    extraModules ? [],
  }:
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.darwinModules.home-manager
          inputs.nix-homebrew.darwinModules.nix-homebrew
          (self + "/hosts/${hostname}")
        ]
        ++ extraModules;
    };

  mkNixosHost = {
    hostname,
    system,
    extraModules ? [],
  }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          (self + "/hosts/${hostname}")
        ]
        ++ extraModules;
    };
}
