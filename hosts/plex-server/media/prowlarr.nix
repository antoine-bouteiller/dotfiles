{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.prowlarr = {
    enable = true;
    dataDir = constants.prowlarr.dataDir;

    settings = {
      auth.method = "external";
      postgres = {
        host = "/run/pgbouncer";
        port = 5432;
        user = "prowlarr";
        mainDb = "prowlarr";
        logDb = "prowlarr-log";
      };
    };
  };

  systemd.services.prowlarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "prowlarr.${constants.network.domain}";
    port = constants.prowlarr.port;
    auth = true;
    extraProxyConfig = "header_down -Access-Control-Allow-Origin";
  };
}
