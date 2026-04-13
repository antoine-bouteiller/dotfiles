{
  config,
  lib,
  ...
}: let
  cfg = config.mediaServer;
  cloudflareIpsV4File = builtins.fetchurl {
    url = "https://www.cloudflare.com/ips-v4";
    sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
  };
  cloudflareIps =
    builtins.filter (s: s != "")
    (lib.splitString "\n" (builtins.readFile cloudflareIpsV4File));
  trustedProxies = builtins.concatStringsSep " " cloudflareIps;
in {
  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;

      globalConfig = ''
        servers {
          trusted_proxies static ${trustedProxies}
        }
      '';

      extraConfig = ''
        (auth_proxy) {
          forward_auth localhost:${toString cfg.authelia.port} {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
            header_down -Authorization
          }
        }
      '';
    };
  };
}
