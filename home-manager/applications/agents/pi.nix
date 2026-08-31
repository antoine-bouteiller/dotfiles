{
  mkModule,
  config,
  osConfig,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
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
in
  mkModule args "local.home-manager.agents.pi" {
    description = "pi's settings.json and hand-vendored extensions (edit-and-go symlinks)";

    # Nix-packaged prebuilt binary (pkgs/pi); settings and vendored extensions
    # stay on edit-and-go symlinks.
    config = _:
      lib.mkIf agents.enable {
        home.packages = [customPkgs.pi];

        home.file = builtins.listToAttrs (map (name: {
            name = ".pi/agent/${name}";
            value.source = mkOutOfStoreSymlink "${piDir}/${name}";
          })
          topLevelFiles);
      };
  }
