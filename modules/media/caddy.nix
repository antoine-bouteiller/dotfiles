{
  config,
  lib,
  pkgs,
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
    sops.secrets."crowdsec/caddy-bouncer" = {};

    sops.templates."caddy-crowdsec.env" = {
      content = ''
        CROWDSEC_API_KEY=${config.sops.placeholder."crowdsec/caddy-bouncer"}
      '';
      owner = "caddy";
    };

    systemd.services.caddy.serviceConfig.EnvironmentFile = [
      config.sops.templates."caddy-crowdsec.env".path
    ];
    services.caddy = {
      enable = true;

      package =
        (pkgs.caddy.withPlugins {
          plugins = [
            "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.0"
            "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.0"
          ];
          hash = "sha256-2ASQpbEgCq9/OYlhs8Ikz6F3FimOAUWxMCPaQ1u1H2k=";
        }).overrideAttrs (oldAttrs: {
          doInstallCheck = false;
        });

      globalConfig = ''
        order crowdsec first

        crowdsec {
          api_url http://127.0.0.1:8080
          api_key {$CROWDSEC_API_KEY:dummy_key}
          ticker_interval 15s
        }
        servers {
          trusted_proxies static 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 ${trustedProxies}
        }
      '';

      extraConfig = ''
        (crowdsec_proxy) {
          log
          crowdsec
        }

        (auth_proxy) {
          import crowdsec_proxy
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
