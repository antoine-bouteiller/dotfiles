{pkgs, ...}: {
  imports = [../modules];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    allowUnsupportedSystem = true;
  };

  nix = {
    package = pkgs.lix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Keep build-time deps (sources, compilers) so GC doesn't force re-fetching them
      keep-outputs = true;
      keep-derivations = true;
      substituters = [
        "https://nix-community.cachix.org"
        "https://antoine-bouteiller.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "antoine-bouteiller.cachix.org-1:vtMtdYM8LJ3CRDrqiTllxXRnu4x3xwYOb6317TUJUTc="
      ];
    };

    # Garbage collection is handled by `nh clean all --keep 2 --keep-since 7d`

    # Hardlink identical store files to save disk space
    optimise.automatic = true;
  };

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    bat
    openssh
    zip
    unzip
    p7zip

    # Text and terminal utilities
    jq
    ripgrep
    tree
    eza

    # Development tools
    curl
    gh
    alejandra
    nixd
    ffmpeg
    sops
    nushell
  ];
}
