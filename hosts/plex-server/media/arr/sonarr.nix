{
  config,
  lib,
  ...
}: let
  constants = import ../shared/constants.nix;
in
  lib.mkMerge [
    (import ./shared.nix {
      inherit config lib;
      name = "sonarr";
      managesMedia = true;
    })
    {
      systemd.tmpfiles.rules = [
        # The module only provisions StateDirectory for its default dataDir.
        "d ${constants.sonarr.dataDir} 0775 ${constants.sonarr.user} ${constants.sonarr.group} - -"
      ];
    }
  ]
