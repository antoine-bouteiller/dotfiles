{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ../modules/nixos
  ];

  networking = {
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };
    hosts = {
      "192.168.1.254" = ["mabbox.bytel.fr"];
    };
    nftables.enable = true;
    firewall.enable = true;
  };

  # DHCP DNS is used per-network (required for captive portals); these are fallbacks.
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = ["1.1.1.1" "9.9.9.9"];
  };

  boot.loader = {
    systemd-boot = {
      enable = lib.mkDefault true;
      consoleMode = "max";
    };
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep 2 --keep-since 7d";
    };
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "fr";

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
