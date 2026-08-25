{
  lib,
  hostUser,
  ...
}: {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    herdr.enable = true;
    hunk.enable = true;
    shell-tools.enable = true;
    agents = {
      enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
    zed.enable = true;
    ghostty.enable = true;
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    username = hostUser;
    homeDirectory = lib.mkForce "/home/${hostUser}";
    stateVersion = "25.11";
  };
}
