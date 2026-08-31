{
  globals,
  inputs,
  modulesPath,
  pkgs,
  self,
  ...
}: {
  imports = ["${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"];

  console.keyMap = "fr";

  environment.systemPackages = [
    pkgs.git
    pkgs.parted
    pkgs.gptfdisk
    pkgs.sops
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
  ];

  # Carry the flake so a reinstall needs no clone. The sops age keys live
  # outside the repo and are still restored by hand.
  environment.etc.dotfiles.source = self;

  users.users.root.openssh.authorizedKeys.keys = globals.sshKeys;
}
