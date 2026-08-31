{
  mkModule,
  inputs,
  ...
} @ args:
mkModule args "local.home-manager.hunk" {
  description = "Hunk diff viewer";
  imports = [inputs.hunk.homeManagerModules.default];
  config = _: {
    programs.hunk.enable = true;
  };
}
