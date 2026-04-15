{config, ...}: let
  cfg = config.mediaServer;
in {
  users.users.crowdsec.extraGroups = [cfg.caddy.group];

  services.crowdsec = {
    enable = true;

    settings = {
      general = {
        common.log_level = "warn";
        api.server = {
          enable = true;
          log_level = "warn";
          listen_uri = "127.0.0.1:8080";
          console_path = "/var/lib/crowdsec/state/console.yaml";
        };
      };
      capi.credentialsFile = "/var/lib/crowdsec/capi-credentials.yaml";
      lapi.credentialsFile = "/var/lib/crowdsec/lapi-credentials.yaml";
    };

    hub = {
      collections = [
        "crowdsecurity/linux"
        "crowdsecurity/caddy"
        "crowdsecurity/appsec-virtual-patching"
        "crowdsecurity/appsec-generic-rules"
      ];
    };

    localConfig.parsers.s02Enrich = [
      {
        name = "local/homepage-whitelist";
        description = "Whitelist Homepage dashboard /api/services/proxy calls";
        whitelist = {
          reason = "Homepage dashboard widget API proxy calls";
          expression = [
            "evt.Parsed.uri startsWith '/api/services/proxy'"
          ];
        };
      }
    ];

    localConfig.acquisitions = [
      {
        filename = "${cfg.caddy.logDir}/*.log";
        labels.type = "caddy";
      }
      {
        appsec_config = "crowdsecurity/appsec-default";
        source = "appsec";
        labels.type = "appsec";
        listen_addr = "127.0.0.1:7422";
      }
    ];
  };
}
