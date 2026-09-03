{
  lib,
  hostUser,
  ...
}: {
  imports = [
    ../../modules/home
  ];

  local.home-manager.workstation.enable = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "26.05";
  };
}
