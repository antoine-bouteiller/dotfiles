{
  lib,
  config,
  ...
}: let
  cfg = config.mediaServer;
  inherit (import ./lib.nix cfg) mkCaddyVirtualHost;
in {
  config = lib.mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      dataDir = cfg.prowlarr.dataDir;

      settings = {
        auth.method = "external";
        postgres = {
          host = "/run/pgbouncer";
          port = 6432;
          user = "prowlarr";
          mainDb = "prowlarr";
          logDb = "prowlarr-log";
        };
      };
    };

    mediaServer.databases = [{
      name = "prowlarr";
      user = "prowlarr";
      extraDatabases = ["prowlarr-log"];
    }];

    systemd.services.prowlarr = {
      after = ["pgbouncer.service"];
      requires = ["pgbouncer.service"];
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "prowlarr.${cfg.network.domain}";
      port = cfg.prowlarr.port;
      auth = true;
      extraProxyConfig = "header_down -Access-Control-Allow-Origin";
    };
  };
}
