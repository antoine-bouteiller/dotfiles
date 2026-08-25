{...}: {
  imports = [
    ./adguard.nix
    ./authelia.nix
    ./caddy.nix
    ./cloudflared.nix
    ./tailscale.nix
  ];
}
