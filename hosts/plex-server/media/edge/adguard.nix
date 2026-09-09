{
  config,
  lib,
  pkgs,
  ...
}: let
  localDomains = lib.unique (map (service: service.domain) (lib.attrValues config.local.media));
  python = pkgs.python3.withPackages (ps: [ps.pyyaml]);
  rewrites = ./adguard-rewrites.py;
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
    # A bounded timer publishes the desired rewrites into a root-owned runtime
    # directory and queues a native restart only when they changed; AdGuard's own
    # pre-start hook applies them while the daemon is stopped, never touching the
    # live YAML. Doing the lookup inside AdGuard is impossible: its sandbox has no
    # AF_UNIX for the tailscaled socket.
    systemd.tmpfiles.rules = ["d ${handoffDir} 0755 root root - -"];

    systemd.timers.adguardhome-tailscale-rewrites = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitInactiveSec = "1min";
      };
    };

    systemd.services.adguardhome-tailscale-rewrites = {
      description = "Reconcile AdGuard Home local DNS rewrites with the Tailscale IP";

      path = [
        pkgs.coreutils
        pkgs.tailscale
        pkgs.systemd
        python
      ];

      environment = {
        ADGUARD_YAML = adguardYaml;
        REWRITES_DESIRED = "${handoffDir}/desired.json";
        LOCAL_DNS_DOMAINS = builtins.concatStringsSep " " localDomains;
      };

      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "10s";
      };

      script = ''
        ip=$(timeout 5s tailscale ip -4 2>/dev/null) || ip=
        if [ -z "$ip" ]; then
          echo "No Tailscale IPv4 address; leaving DNS rewrites unchanged"
          exit 0
        fi
        rc=0
        # shellcheck disable=SC2086
        python ${rewrites} check "$ADGUARD_YAML" "$REWRITES_DESIRED" "$ip" $LOCAL_DNS_DOMAINS || rc=$?
        case $rc in
          0) ;;
          1) systemctl --no-block try-restart adguardhome.service ;;
          *) exit "$rc" ;;
        esac
      '';
    };

    systemd.services.adguardhome.preStart = lib.mkAfter ''
      ${python}/bin/python ${rewrites} apply ${handoffDir}/desired.json ${adguardYaml} \
        || echo "AdGuard rewrite update failed; retaining working DNS configuration" >&2
    '';
  };
}
