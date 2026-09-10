{
  config,
  host,
  lib,
  pkgs,
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

  # HiDPI workaround: 3840x2400 panel at 200% display scale renders Steam's
  # CEF bootstrap UI off-center and crops it. Force Steam's own 2x scaling.
  programs.steam.package = pkgs.steam.override {
    extraEnv.STEAM_FORCE_DESKTOPUI_SCALING = "2";
  };

  # RTX 2080 SUPER (Turing): supported by the open kernel module.
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.open = true;

  programs.coolercontrol.enable = true;

  # Keep the OS picker visible for Windows dual boot.
  boot.loader.timeout = 5;

  system.stateVersion = "26.05";
}
