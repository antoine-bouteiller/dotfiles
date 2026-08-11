{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.hunk.homeManagerModules.default];

  options.local.home-manager.hunk.enable = lib.mkEnableOption "Hunk diff viewer";

  config = lib.mkIf config.local.home-manager.hunk.enable {
    programs.hunk.enable = true;
  };
}
