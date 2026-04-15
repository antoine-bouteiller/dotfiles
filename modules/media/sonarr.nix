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
    services.sonarr = {
      enable = true;
      dataDir = cfg.sonarr.dataDir;
      group = cfg.libraryOwner.group;

      settings = {
        server.bindAddress = "*";
        auth.method = "external";
        postgres = {
          host = "/run/pgbouncer";
          port = 5432;
          user = "sonarr";
          mainDb = "sonarr";
          logDb = "sonarr-log";
        };
      };
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "sonarr.${cfg.network.domain}";
      port = cfg.sonarr.port;
      auth = true;
      extraProxyConfig = "header_down -Access-Control-Allow-Origin";
    };

    mediaServer.databases = [{
      name = "sonarr";
      user = "sonarr";
      extraDatabases = ["sonarr-log"];
    }];

    systemd.services.sonarr = {
      after = ["pgbouncer.service"];
      requires = ["pgbouncer.service"];
      serviceConfig.UMask = pkgs.lib.mkForce "002";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.paths.mediaDir}/torrents/sonarr' 0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    ];

    users.users.sonarr.extraGroups = [cfg.libraryOwner.group];
  };
}
