{pkgs, ...}: {
  imports = [../modules/common];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    allowUnsupportedSystem = true;
  };

  nix = {
    package = pkgs.lix;

    settings =
      (builtins.fromJSON (builtins.readFile ../lib/nix-settings.json))
      // {
        warn-dirty = false;
        # Keep build-time deps (sources, compilers) so GC doesn't force re-fetching them
        keep-outputs = true;
        keep-derivations = true;
      };

    # Garbage collection is handled by `nh clean all --keep 2 --keep-one`

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
