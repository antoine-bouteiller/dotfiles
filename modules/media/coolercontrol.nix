{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
  inherit (import ./lib.nix cfg) mkCaddyVirtualHost;
in {
  config = lib.mkIf cfg.enable {
    programs.coolercontrol.enable = true;

    services.caddy.virtualHosts = mkCaddyVirtualHost {
      url = "coolercontrol.${cfg.network.domain}";
      port = cfg.coolercontrol.port;
      auth = true;
    };
  };
}
