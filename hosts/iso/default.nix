{
  globals,
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
  ];

  # Carry the flake so a reinstall that keeps its sops age key needs no clone.
  environment.etc.dotfiles.source = self;

  users.users.root.openssh.authorizedKeys.keys = globals.sshKeys;
}
