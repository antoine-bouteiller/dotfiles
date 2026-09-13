{
  inputs,
  lib,
  ...
}: {
  imports =
    lib.optional (builtins.pathExists (inputs.privateConfig + "/home.nix")) (inputs.privateConfig + "/home.nix")
    ++ [
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
