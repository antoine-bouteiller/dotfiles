{caddy}:
(caddy.withPlugins {
  plugins = [
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.0"
  ];
  hash = "sha256-2ASQpbEgCq9/OYlhs8Ikz6F3FimOAUWxMCPaQ1u1H2k=";
})
.overrideAttrs (_: {
  doInstallCheck = false;
})
