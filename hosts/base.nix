{
  config,
  pkgs,
  ...
}: {
  imports = [../modules/common];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    allowInsecure = false;
    allowUnsupportedSystem = true;
  };

  nix = {
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

  # Written by bootstrap or `nix run .#rekey`; recipients must stay independent of SSH host keys.
  sops = {
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];
  };
  # The key is root-only; the user's `sops` reads it through sudo.
  environment.variables.SOPS_AGE_KEY_CMD = "sudo cat ${config.sops.age.keyFile}";

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
    alejandra
    nixd
    ffmpeg
    sops
    nushell
  ];
}
