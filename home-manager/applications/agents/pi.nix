{
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.home-manager.agents;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  piDir = "${osConfig.flakePath}/agents/pi";

  topLevelFiles = [
    "AGENTS.md"
    "APPEND_SYSTEM.md"
    "themes"
    "node_modules"
    "settings.json"
    "models.json"
  ];
in {
  # Nix-packaged prebuilt binary (pkgs/pi); settings and vendored extensions
  # stay on edit-and-go symlinks.
  config = lib.mkIf (cfg.enable && cfg.pi.enable) {
    home.packages = [customPkgs.pi];

    home.file = builtins.listToAttrs (map (name: {
        name = ".pi/agent/${name}";
        value.source = mkOutOfStoreSymlink "${piDir}/${name}";
      })
      topLevelFiles);
  };
}
