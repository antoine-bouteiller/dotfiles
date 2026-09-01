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
  console = {
    keyMap = "fr";
    # Catppuccin Mocha, from github:catppuccin/tty -- the option compiles down to the
    # vt.default_red/grn/blu kernel params that theme carries. It only reaches the Linux
    # VT, never the bootloader, which draws with the firmware's own fixed EFI palette.
    colors = [
      "1e1e2e"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "bac2de"
      "585b70"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "a6adc8"
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
