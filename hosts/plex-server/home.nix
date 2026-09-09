{
  lib,
  host,
  ...
}: {
  imports = [
    ../../modules/home
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = host.user;
    homeDirectory = lib.mkForce "/home/${host.user}";
    stateVersion = "25.11";
  };
}
