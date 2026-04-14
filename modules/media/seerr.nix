{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
  inherit (import ./lib.nix cfg) mkCaddyVirtualHost;
in {
  config = lib.mkIf cfg.enable {
    services.seerr = {
      enable = true;
      configDir = cfg.seerr.dataDir;
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = cfg.network.domain;
      port = cfg.seerr.port;
    };

    systemd.services.seerr = {
      environment = {
        LOG_LEVEL = "info";
      };
    };
  };
}
