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
          host = "/run/postgresql";
          port = 5432;
          user = "prowlarr";
          mainDb = "prowlarr";
          logDb = "prowlarr-log";
        };
      };
    };

    services.postgresql = {
      ensureDatabases = ["prowlarr" "prowlarr-log"];
      ensureUsers = [
        {
          name = "prowlarr";
        }
      ];
    };

    systemd.services.postgresql-setup.script = lib.mkAfter ''
      psql -tAc "ALTER DATABASE \"prowlarr\" OWNER TO prowlarr"
      psql -tAc "ALTER DATABASE \"prowlarr-log\" OWNER TO prowlarr"
    '';

    systemd.services.prowlarr = {
      after = ["postgresql-setup.service"];
      requires = ["postgresql-setup.service"];
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "prowlarr.${cfg.network.domain}";
      port = cfg.prowlarr.port;
      auth = true;
      extraProxyConfig = "header_down -Access-Control-Allow-Origin";
    };
  };
}
