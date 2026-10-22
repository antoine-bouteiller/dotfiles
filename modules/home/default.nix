{inputs, ...}: {
  imports = [
    inputs.privateConfig.homeModules.default
    ./source-path.nix
    ./os-toggles.nix
    ./profiles
    ./desktop
    ./gaming.nix
    ./shell
    ./applications
    ./wm
  ];
}
