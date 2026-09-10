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
  # The iso host has no user entry.
  mkSpecialArgs = name: let
    host = globals.hosts.${name} or {};
  in {
    common = {inherit inputs globals host mkModule self;};
  };
in {
  mkDarwinHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }: let
    hostDir = self + "/hosts/${name}";
    specialArgs = mkSpecialArgs name;
  in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = specialArgs.common;
      modules =
        [
          home-manager.darwinModules.home-manager
          # Declared here rather than in modules/common, because it is set here and
          # the iso host imports no common modules at all.
          (self + "/modules/common/host-dir.nix")
          {
            networking.hostName = hostname;
            local.hostDir = hostDir;
          }
          hostDir
        ]
        ++ extraModules;
    };

  mkNixosHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }: let
    hostDir = self + "/hosts/${name}";
    specialArgs = mkSpecialArgs name;
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = specialArgs.common;
      modules =
        [
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          (self + "/modules/common/host-dir.nix")
          {
            networking.hostName = nixpkgs.lib.mkDefault hostname;
            local.hostDir = hostDir;
          }
          hostDir
        ]
        ++ extraModules;
    };
}
