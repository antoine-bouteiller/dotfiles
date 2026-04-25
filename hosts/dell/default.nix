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

  desktop.enable = true;

  environment.systemPackages = with pkgs; [
    brave
    packet
  ];

  environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;
    BraveWalletDisabled = true;
    BraveVPNDisabled = true;
    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    BraveTalkDisabled = true;
    TorDisabled = true;
    DnsOverHttpsMode = "automatic";
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
