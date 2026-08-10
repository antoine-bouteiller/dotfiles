{config, ...}: {
  # One-time bootstrap after first deploy:
  #   sudo tailscale up
  #
  # Then configure Tailscale DNS in the admin console:
  #   - Add a restricted nameserver for the public media domain.
  #   - Use this host's `tailscale ip -4` address as the nameserver.
  services.tailscale = {
    enable = true;
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  # Keep tailnet DNS enabled globally, but do not install it on this IPv4-only host.
  services.tailscale.extraSetFlags = [
    "--netfilter-mode=nodivert"
    "--accept-dns=false"
  ];

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [
      53
      80
      443
    ];
    allowedUDPPorts = [53];
  };

  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
}
