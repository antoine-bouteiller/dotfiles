{
  config,
  lib,
  ...
}: {
  imports = [
    ./niri
    ./paneru.nix
  ];

  # Exception to imports-only: the WM default follows from having a desktop at all.
  local.home-manager.niri.enable = lib.mkDefault config.local.home-manager.desktop.enable;
}
