{mkModule, ...} @ args:
mkModule args "local.nixos.tailscale" {
  description = "Tailscale";

  config = _: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];
  };
}
