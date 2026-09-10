# The one place a home toggle reads the system side. `or false` is load-bearing on
# darwin, where modules/nixos is never imported and `local.nixos` does not exist.
{
  lib,
  config,
  ...
} @ args: let
  systemConfig = args.osConfig or (config._module.args.osConfig or {});
in {
  local.home-manager = {
    desktop.enable = lib.mkDefault (systemConfig.local.nixos.desktop.enable or false);
    gaming.enable = lib.mkDefault (systemConfig.local.nixos.gaming.enable or false);
  };
}
