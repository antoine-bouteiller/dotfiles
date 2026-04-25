{pkgs, ...}: {
  imports = [
    ./base.nix
    ../modules/desktop.nix
  ];

  networking.networkmanager.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services.xserver.xkb = {
    layout = "fr";
    variant = "azerty";
  };

  programs.zsh.enable = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "fr";

  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
