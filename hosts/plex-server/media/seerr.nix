{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.seerr = {
    enable = true;
    configDir = constants.seerr.dataDir;
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = constants.network.domain;
    port = constants.seerr.port;
  };

  systemd.services.seerr = {
    environment = {
      LOG_LEVEL = "info";
    };
  };
}
