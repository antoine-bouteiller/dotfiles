{lib, ...}: {
  options.flakePath = lib.mkOption {
    type = lib.types.str;
    description = "Absolute path to the flake directory on this host. Used by auto-upgrade and home-manager modules that need to reference repo-local files at runtime.";
  };
}
