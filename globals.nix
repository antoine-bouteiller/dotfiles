{inputs}: let
  privateConfig = import ./lib/private-config.nix inputs.privateConfig;
in
  builtins.seq privateConfig {
    name = "Antoine Bouteiller";
    # Default Git identity; private GitLab remote-hostname matching may override it.
    email = "115460763+antoine-bouteiller@users.noreply.github.com";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlczrZU/ZG/rKQomLJYjLM4hDDMwYvge2Rl2OLQWojG antoinebouteiller@desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfK4sKI0QpEbaADjQm/7bK3DlNY/akOh+6yC+q3aG17 work-key"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJf/EE7y7ua7CVtBHXJqSN+jl5xN+c2hKyjI3oVFG9LT antoinebouteiller@antoine-dell"
    ];
    # Keyed by hosts/<name>; passed to every module as the `host` special arg.
    hosts = {
      macbook = {
        user = "antoinebouteiller";
      };
      vm = {
        user = privateConfig.vmUser;
      };
      desktop.user = "antoinebouteiller";
      dell.user = "antoinebouteiller";
      plex-server.user = "antoineb";
    };
  }
