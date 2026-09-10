{
  config,
  host,
  lib,
  ...
}: let
  inherit (host) user;
in {
  imports =
    [../base-nixos.nix]
    ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  assertions = [
    {
      assertion = builtins.pathExists ./hardware-configuration.nix;
      message = "desktop: generate and git add hosts/desktop/hardware-configuration.nix before installing; see README.md.";
    }
  ];

  flakePath = "${config.users.users.${user}.home}/dotfiles";

  local.nixos.workstation.enable = true;
  local.nixos.gaming.enable = true;
  secureBoot.enable = true;

  # RTX 2080 SUPER (Turing): supported by the open kernel module.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.open = true;

  programs.coolercontrol.enable = true;

  # Keep the OS picker visible for Windows dual boot.
  boot.loader.timeout = 5;

  system.stateVersion = "26.05";
}
