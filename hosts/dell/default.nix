{
  globals,
  inputs,
  pkgs,
  ...
}: let
  user = globals.user;
in {
  imports = [
    ../base-nixos.nix
  ];

  flakePath = "/home/${user}/.dotfiles";

  wsl = {
    enable = true;
    defaultUser = user;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs globals;
      hostUser = user;
    };
    users.${user} = import ./home.nix;
  };

  users.defaultUserShell = pkgs.zsh;
  users.users.${user} = {
    isNormalUser = true;
    description = globals.name;
    extraGroups = ["networkmanager" "wheel"];
  };

  system.stateVersion = "25.11";
}
