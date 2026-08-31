# Collapses the boilerplate of the `local.<path>.enable` toggle pattern: declares
# the option, binds `cfg`, and wraps the body in `mkIf cfg.enable`.
#
#   {mkModule, ...} @ args:
#     mkModule args "local.home-manager.hunk" {
#       description = "Hunk diff viewer";
#       config = {cfg}: {programs.hunk.enable = true;};
#     }
lib: args: name: {
  description,
  imports ? [],
  options ? {},
  config,
}: let
  path = lib.splitString "." name;
  cfg = lib.attrByPath path {} args.config;
in {
  inherit imports;
  options = lib.setAttrByPath path ({enable = lib.mkEnableOption description;} // options);
  config = lib.mkIf cfg.enable (config {inherit cfg;});
}
