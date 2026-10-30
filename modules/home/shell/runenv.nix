{
  mkModule,
  config,
  pkgs,
  lib,
  ...
} @ args:
mkModule args "local.home-manager.runenv" {
  description = "runenv (per-command sops secret injection)";

  options = {
    secretsDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory holding per-namespace sops-encrypted <ns>.yaml files.";
    };

    defaultNamespace = lib.mkOption {
      type = lib.types.str;
      description = "Namespace used when the first argument is not a namespace.";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      description = "Path to the age private key sops uses to decrypt.";
    };

    sopsAgeKeyHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "ssh host patterns that receive the age key as SOPS_AGE_KEY (their sshd needs AcceptEnv SOPS_AGE_KEY).";
    };
  };

  config = {cfg}: {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];
    home.sessionVariables.SOPS_AGE_KEY_FILE = cfg.ageKeyFile;
    programs.ssh.settings = lib.genAttrs cfg.sopsAgeKeyHosts (_: {SendEnv = ["SOPS_AGE_KEY"];});

    # runenv <namespace> <cmd> [args...] — decrypts secrets/<namespace>.yaml into the
    # environment of that one command (in memory), never the parent shell or disk.
    programs.zsh.initContent = lib.mkAfter (''
        runenv() {
          emulate -L zsh
          local ns=${lib.escapeShellArg cfg.defaultNamespace}
          # first arg is the namespace only if secrets/<arg>.yaml exists, else default
          if [[ -f ${lib.escapeShellArg cfg.secretsDir}/"$1".yaml ]]; then ns="$1"; shift; fi
          # ''${(@q)@} quotes each arg so spaces survive sops's single command string
          sops exec-env ${lib.escapeShellArg cfg.secretsDir}/"$ns".yaml "''${(j: :)''${(@q)@}}"
        }
      ''
      # Remote sops reads SOPS_AGE_KEY before SOPS_AGE_KEY_FILE. Set per ssh call so the key
      # stays out of the shell's environment.
      + lib.optionalString (cfg.sopsAgeKeyHosts != []) ''
        ssh() {
          if [[ -z ''${SOPS_AGE_KEY:-} && -r ${lib.escapeShellArg cfg.ageKeyFile} ]]; then
            SOPS_AGE_KEY=$(<${lib.escapeShellArg cfg.ageKeyFile}) command ssh "$@"
          else
            command ssh "$@"
          fi
        }
      '');
  };
}
