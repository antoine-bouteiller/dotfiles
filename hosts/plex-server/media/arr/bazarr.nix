{config, ...}: let
  constants = import ../shared/constants.nix;
in {
  sops.secrets."bazarr/gemini_api_key" = {
    key = "google_api_key";
    restartUnits = ["bazarr.service"];
  };

  sops.templates."bazarr.env".content = ''
    DYNACONF_TRANSLATOR__GEMINI_KEYS='["${config.sops.placeholder."bazarr/gemini_api_key"}"]'
  '';

  services.bazarr = {
    enable = true;
    group = constants.libraryOwner.group;
    dataDir = constants.bazarr.dataDir;
  };

  systemd.services.bazarr = {
    after = ["pgbouncer.service"];
    requires = ["pgbouncer.service"];
    serviceConfig.EnvironmentFile = [config.sops.templates."bazarr.env".path];
    environment = {
      DYNACONF_TRANSLATOR__TRANSLATOR_TYPE = "gemini";
      DYNACONF_TRANSLATOR__GEMINI_MODEL = "gemini-3.5-flash-lite";
      POSTGRES_ENABLED = "true";
      POSTGRES_HOST = "/run/pgbouncer";
      POSTGRES_PORT = "5432";
      POSTGRES_DATABASE = "bazarr";
      POSTGRES_USERNAME = "bazarr";
    };
  };

  local.media.bazarr = {
    port = config.services.bazarr.listenPort;
    auth = true;
  };

  users.users.bazarr.isSystemUser = true;
  users.users.bazarr.group = constants.libraryOwner.group;
}
