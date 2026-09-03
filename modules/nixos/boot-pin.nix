# A generation pinned by `nix run .#pin` leaves its boot entry in the host directory;
# its presence is the switch, so there is nothing to toggle.
{
  config,
  lib,
  ...
}: let
  pinned = config.local.hostDir + "/pinned-boot-entry.conf";
in {
  boot.loader.systemd-boot.extraEntries =
    lib.optionalAttrs (config.boot.loader.systemd-boot.enable && lib.pathExists pinned)
    {"pinned-stable.conf" = lib.readFile pinned;};
}
