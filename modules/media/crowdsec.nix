_: {
  services.crowdsec = {
    enable = true;

    settings.general.api.server = {
      enable = true;
      listen_uri = "127.0.0.1:8080";
      console_path = "/var/lib/crowdsec/state/console.yaml";
    };
    settings.capi.credentialsFile = "/var/lib/crowdsec/capi-credentials.yaml";
    settings.lapi.credentialsFile = "/var/lib/crowdsec/lapi-credentials.yaml";

    hub = {
      collections = [
        "crowdsecurity/linux"
        # "crowdsecurity/sshd"
        "crowdsecurity/caddy"
      ];
    };

    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = ["_SYSTEMD_UNIT=caddy.service"];
        labels.type = "caddy";
      }
    ];
  };
}
