{
  lib,
  host,
  ...
}: {
  imports = [
    ../../modules/home
  ];

  local.home-manager.workstation.enable = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    username = host.user;
    homeDirectory = lib.mkForce "/home/${host.user}";
    stateVersion = "26.05";
  };
}
