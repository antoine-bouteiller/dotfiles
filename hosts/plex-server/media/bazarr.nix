{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.bazarr = {
    enable = true;
    group = constants.libraryOwner.group;
    dataDir = constants.bazarr.dataDir;
  };

  systemd.services.bazarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    environment = {
      POSTGRES_ENABLED = "true";
      POSTGRES_HOST = "/run/pgbouncer";
      POSTGRES_PORT = "5432";
      POSTGRES_DATABASE = "bazarr";
      POSTGRES_USERNAME = "bazarr";
    };
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "bazarr.${constants.network.domain}";
    port = constants.bazarr.port;
    auth = true;
  };

  users.users.bazarr.isSystemUser = true;
  users.users.bazarr.group = constants.libraryOwner.group;
}
