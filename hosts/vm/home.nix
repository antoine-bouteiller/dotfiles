{
  host,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [../../modules/home];

  # Shared modules use the checkout path normally supplied by NixOS/nix-darwin.
  # apply-remote builds from GitHub without a checkout, so point at the flake's store copy.
  _module.args.osConfig.flakePath = "${inputs.self}";

  local.home-manager = {
    shell-tools.enable = true;
    herdr.enable = true;
    agents = {
      enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
  };

  home = {
    username = host.user;
    homeDirectory = "/home/${host.user}";
    stateVersion = "26.05";
    packages = [pkgs.bat];
  };

  # Standalone HM cannot change the login shell; hand interactive bash off to zsh.
  programs.bash = {
    enable = true;
    initExtra = "exec ${lib.getExe pkgs.zsh} -l";
  };

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
}
