{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
in {
  config = lib.mkIf cfg.enable {
    services.seerr = {
      enable = true;
      configDir = cfg.seerr.dataDir;
    };

    services.caddy.virtualHosts."${cfg.network.domain}" = {
      extraConfig = "reverse_proxy localhost:${toString cfg.seerr.port}";
    };
  };
}
