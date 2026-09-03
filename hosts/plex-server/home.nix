{
  lib,
  hostUser,
  ...
}: {
  imports = [
    ../../modules/home
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "25.11";
  };
}
