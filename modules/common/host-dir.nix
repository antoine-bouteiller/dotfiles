{lib, ...}: {
  options.local.hostDir = lib.mkOption {
    type = lib.types.path;
    readOnly = true;
    description = "This host's source directory under hosts/. Set by mkNixosHost/mkDarwinHost, and readable from outside the evaluation with `nix eval`, which a specialArg would not be.";
  };
}
