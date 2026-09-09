{
  config,
  pkgs,
  ...
}: {
  imports = [../../modules/home];

  # Shared modules use the checkout path normally supplied by NixOS/nix-darwin.
  _module.args.osConfig.flakePath = "${config.home.homeDirectory}/dotfiles";

  local.home-manager = {
    shell-tools.enable = true;
    agents = {
      enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
  };

  home = {
    username = (let value = builtins.getEnv "VM_USER"; in if value == "" then throw "Set VM_USER and evaluate with --impure" else value);
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "26.05";
    packages = [pkgs.bat];
  };

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
}
