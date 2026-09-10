{...}: {
  imports = [
    ./byparr.nix
    ./gluetun.nix
    ./qbittorrent.nix
  ];

  # This bundle owns the container runtime shared by its containers.
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "podman";
}
