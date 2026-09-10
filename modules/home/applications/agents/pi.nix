{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  piDir = "${config.local.home-manager.sourcePath}/agents/pi";

  secretFiles = ["${config.local.home-manager.sourcePath}/secrets/agent.yaml"] ++ agents.pi.extraSecretFiles;

  # pi runs with the agent API keys decrypted into its own process only.
  # sops exec-env takes one file, so each extra file wraps the command in another layer.
  piWrapped = pkgs.writeShellScriptBin "pi" ''
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-${config.home.homeDirectory}/.config/sops/age/keys.txt}"
    cmd="${lib.getExe customPkgs.pi} $(printf '%q ' "$@")"
    for f in ${lib.escapeShellArgs secretFiles}; do
      cmd="${lib.getExe pkgs.sops} exec-env $f $(printf '%q' "$cmd")"
    done
    eval exec "$cmd"
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

    options.extraSecretFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional sops files decrypted into pi's environment, alongside secrets/agent.yaml.";
    };

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
