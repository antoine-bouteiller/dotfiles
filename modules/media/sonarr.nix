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
          host = "/run/postgresql";
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

    services.postgresql = {
      ensureDatabases = ["sonarr" "sonarr-log"];
      ensureUsers = [
        {
          name = "sonarr";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.postgresql-setup.script = pkgs.lib.mkAfter ''
      psql -tAc "ALTER DATABASE \"sonarr-log\" OWNER TO sonarr"
    '';

    systemd.services.sonarr = {
      after = ["postgresql-setup.service"];
      requires = ["postgresql-setup.service"];
      serviceConfig.UMask = pkgs.lib.mkForce "002";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.paths.mediaDir}/torrents/sonarr' 0775 ${cfg.libraryOwner.user} ${cfg.libraryOwner.group} - -"
    ];

    users.users.sonarr.extraGroups = [cfg.libraryOwner.group];
  };
}
