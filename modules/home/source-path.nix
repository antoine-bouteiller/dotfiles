{lib, ...}: {
  options.local.home-manager.sourcePath = lib.mkOption {
    type = lib.types.str;
    description = "Checkout (or store copy) of this flake that home modules reference at runtime: agent skills/config, Zed files, zsh dotfiles, encrypted secrets.";
  };
}
