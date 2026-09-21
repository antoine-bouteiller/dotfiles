{...}: {
  imports = [
    ./adguard
    ./authelia.nix
    ./caddy.nix
    ./cloudflared.nix
    ./tailscale.nix
  ];
}
