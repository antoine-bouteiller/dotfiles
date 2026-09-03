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
  commonSpecialArgs = {inherit inputs globals mkModule self;};
  # Home-manager modules don't inherit the system specialArgs.
  hmSpecialArgs = {home-manager.extraSpecialArgs = {inherit mkModule;};};
in {
  mkDarwinHost = {
    hostname,
    system,
    name ? hostname,
    extraModules ? [],
  }: let
    hostDir = self + "/hosts/${name}";
  in
    darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.darwinModules.home-manager
          hmSpecialArgs
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
  in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules =
        [
          home-manager.nixosModules.home-manager
          hmSpecialArgs
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
