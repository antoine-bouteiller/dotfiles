{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  programs.coolercontrol.enable = true;

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "coolercontrol.${constants.network.domain}";
    port = constants.coolercontrol.port;
    auth = true;
  };
}
