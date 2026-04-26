{caddy}:
(caddy.withPlugins {
  plugins = [
    "github.com/hslatman/caddy-crowdsec-bouncer/http@v0.12.0"
    "github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.12.0"
  ];
  hash = "sha256-ZDGq4YMVDVwgHd09HGiwI6kTnxbFMNwGWjkothXX5X8=";
})
.overrideAttrs (_: {
  doInstallCheck = false;
})
