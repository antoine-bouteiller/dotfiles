{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
  inherit (import ./lib.nix cfg) mkCaddyVirtualHost;
in {
  config = lib.mkIf cfg.enable {
    services.radarr = {
      enable = true;
      dataDir = cfg.radarr.dataDir;
      group = cfg.libraryOwner.group;

      settings = {
        server.bindAddress = "*";
        auth.method = "external";
        postgres = {
          host = "/run/pgbouncer";
          port = 5432;
          user = "radarr";
          mainDb = "radarr";
          logDb = "radarr-log";
        };
      };
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "radarr.${cfg.network.domain}";
      port = cfg.radarr.port;
      auth = true;
      extraProxyConfig = "header_down -Access-Control-Allow-Origin";
    };

    mediaServer.databases = [{
      name = "radarr";
      user = "radarr";
      extraDatabases = ["radarr-log"];
    }];

    systemd.services.radarr = {
      after = ["pgbouncer.service"];
      requires = ["pgbouncer.service"];
      serviceConfig.UMask = pkgs.lib.mkForce "002";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.paths.mediaDir}/torrents/radarr' 0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    ];

    users.users.radarr.extraGroups = [cfg.libraryOwner.group];
  };
}
