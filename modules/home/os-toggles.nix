# The one place a home toggle reads the system side. `or false` is load-bearing on
# darwin, where modules/nixos is never imported and `local.nixos` does not exist.
{
  osConfig,
  lib,
  ...
}: {
  local.home-manager = {
    desktop.enable = lib.mkDefault (osConfig.local.nixos.desktop.enable or false);
    gaming.enable = lib.mkDefault (osConfig.local.nixos.gaming.enable or false);
  };
}
