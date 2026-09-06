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

  # pi runs with the agent API keys decrypted into its own process only.
  piWrapped = pkgs.writeShellScriptBin "pi" ''
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-${config.home.homeDirectory}/.config/sops/age/keys.txt}"
    exec ${lib.getExe pkgs.sops} exec-env ${osConfig.flakePath}/secrets/agent.yaml \
      "${lib.getExe customPkgs.pi} $(printf '%q ' "$@")"
  '';

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
        home.packages = [piWrapped];

        home.file = builtins.listToAttrs (map (name: {
            name = ".pi/agent/${name}";
            value.source = mkOutOfStoreSymlink "${piDir}/${name}";
          })
          topLevelFiles);
      };
  }
