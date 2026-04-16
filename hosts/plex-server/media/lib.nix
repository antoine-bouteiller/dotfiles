let
  constants = import ./constants.nix;
in {
  mkCaddyVirtualHost = {
    url,
    port,
    auth ? false,
    extraProxyConfig ? "",
  }: {
    "${url}" = {
      extraConfig =
        if extraProxyConfig != ""
        then ''
          ${
            if auth
            then "import auth_proxy"
            else "import crowdsec_proxy"
          }
          reverse_proxy localhost:${toString port} {
            ${extraProxyConfig}
          }
        ''
        else ''
          ${
            if auth
            then "import auth_proxy"
            else "import crowdsec_proxy"
          }
          reverse_proxy localhost:${toString port}
        '';
      logFormat = ''
        output file ${constants.caddy.logDir}/access-${url}.log {
          roll_size 10MiB
          roll_keep 3
        }
      '';
    };
  };
}
