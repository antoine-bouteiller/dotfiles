{
  globals,
  host,
  lib,
  pkgs,
  ...
}: let
  inherit (import ../lib/palette.nix {inherit lib;}) colors;
in {
  imports = [
    ./base.nix
    ../modules/nixos
  ];

  networking = {
    networkmanager.enable = true;
    hosts = {
      "192.168.1.254" = ["mabbox.bytel.fr"];
    };
    nftables.enable = true;
    firewall.enable = true;
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
      extraArgs = "--keep 2 --keep-one";
    };
  };

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    keyMap = "fr";
    # The shared Graphite palette becomes vt.default_red/grn/blu kernel params.
    # This only reaches the Linux VT, not the bootloader's fixed EFI palette.
    colors = map (lib.removePrefix "#") (with colors; [
      background
      red
      green
      yellow
      blue
      pink
      teal
      textSecondary
      surfaceHover
      red
      green
      yellow
      blue
      pink
      teal
      textMuted
    ]);
  };

  users = {
    defaultUserShell = pkgs.zsh;
    users.${host.user} = {
      isNormalUser = true;
      description = globals.name;
      extraGroups = ["networkmanager" "wheel"];
    };
  };

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
