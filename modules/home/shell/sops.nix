{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops.age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";
}
