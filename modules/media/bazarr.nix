{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
  inherit (import ./lib.nix cfg) mkCaddyVirtualHost;
in {
  config = lib.mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      group = cfg.libraryOwner.group;
      dataDir = cfg.bazarr.dataDir;
    };

    services.postgresql = {
      ensureDatabases = ["bazarr"];
      ensureUsers = [
        {
          name = "bazarr";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.bazarr = {
      after = ["postgresql-setup.service"];
      requires = ["postgresql-setup.service"];
      environment = {
        POSTGRES_ENABLED = "true";
        POSTGRES_HOST = "/run/postgresql";
        POSTGRES_PORT = "5432";
        POSTGRES_DATABASE = "bazarr";
        POSTGRES_USERNAME = "bazarr";
      };
    };

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "bazarr.${cfg.network.domain}";
      port = cfg.bazarr.port;
      auth = true;
    };

    users.users.bazarr.isSystemUser = true;
    users.users.bazarr.group = cfg.libraryOwner.group;
  };
}
