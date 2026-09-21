{
  config,
  lib,
  pkgs,
  ...
}: let
  localDomains = lib.unique (map (service: service.domain) (lib.attrValues config.local.media));
  rewrites = "${pkgs.nushell}/bin/nu --no-config-file ${./rewrites.nu}";
  adguardYaml = "/var/lib/AdGuardHome/AdGuardHome.yaml";
  handoffDir = "/run/adguardhome-tailscale-rewrites";
in {
  config = {
    local.media.adguard = {
      port = config.services.adguardhome.port;
    };

    # AdGuard owns port 53 on every address, so resolved would have nowhere to
    # listen: it stays off and /etc/resolv.conf is pinned to AdGuard instead.
    # The host then resolves the local media domains through its own rewrites
    # and everything else through Cloudflare DoH, never the ISP resolver.
    services.resolved.enable = false;
    networking = {
      networkmanager.dns = "none";
      nameservers = ["127.0.0.1"];
    };

    services.adguardhome = {
      enable = true;
      # Bind only the admin UI to loopback; DNS remains available on Tailscale.
      host = "127.0.0.1";
      port = 3000;
      mutableSettings = true;
      settings = {
        dns = {
          bind_hosts = ["0.0.0.0"];
          port = 53;
          upstream_dns = ["https://dns.cloudflare.com/dns-query"];
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
      };
    };

    # AdGuard is the host's only resolver, so it must start without Tailscale.
    # A once-per-boot service publishes rewrites into a root-owned runtime
    # directory and queues a native restart only when they changed; AdGuard's own
    # pre-start hook applies them while the daemon is stopped, never touching the
    # live YAML. Doing the lookup inside AdGuard is impossible: its sandbox has no
    # AF_UNIX for the tailscaled socket.
    systemd.tmpfiles.rules = ["d ${handoffDir} 0755 root root - -"];

    systemd.services.adguardhome-tailscale-rewrites = {
      description = "Resolve AdGuard Home local DNS rewrites once at boot";
      wantedBy = ["multi-user.target"];
      wants = ["adguardhome.service" "tailscaled.service"];
      after = ["adguardhome.service" "tailscaled.service"];

      path = [
        pkgs.coreutils
        pkgs.tailscale
        pkgs.systemd
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "70s";
      };

      script = ''
        ${rewrites} resolve ${adguardYaml} ${handoffDir}/rewrites.json ${lib.escapeShellArgs localDomains}
      '';
    };

    systemd.services.adguardhome.preStart = lib.mkAfter ''
      ${rewrites} apply ${handoffDir}/rewrites.json ${adguardYaml} \
        || echo "AdGuard rewrite update failed; retaining working DNS configuration" >&2
    '';
  };
}
