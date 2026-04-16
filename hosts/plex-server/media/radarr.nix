{pkgs, ...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.radarr = {
    enable = true;
    dataDir = constants.radarr.dataDir;
    group = constants.libraryOwner.group;

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
    url = "radarr.${constants.network.domain}";
    port = constants.radarr.port;
    auth = true;
    extraProxyConfig = "header_down -Access-Control-Allow-Origin";
  };

  systemd.services.radarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.UMask = pkgs.lib.mkForce "002";
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/torrents/radarr' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.radarr.extraGroups = [constants.libraryOwner.group];
}
