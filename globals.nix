let
  personal = "115460763+antoine-bouteiller@users.noreply.github.com";
  work = let
    value = builtins.getEnv "WORK_EMAIL";
  in
    if value == ""
    then throw "Set WORK_EMAIL and evaluate with --impure"
    else value;
in {
  name = "Antoine Bouteiller";
  # GitHub identity: the default git email, and always used for GitHub remotes.
  email = personal;
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILlczrZU/ZG/rKQomLJYjLM4hDDMwYvge2Rl2OLQWojG antoinebouteiller@desktop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfK4sKI0QpEbaADjQm/7bK3DlNY/akOh+6yC+q3aG17 work-key"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJf/EE7y7ua7CVtBHXJqSN+jl5xN+c2hKyjI3oVFG9LT antoinebouteiller@antoine-dell"
  ];
  # Keyed by hosts/<name>; passed to every module as the `host` special arg.
  # gitEmail overrides `email` for non-GitHub remotes.
  hosts = {
    macbook = {
      user = "antoinebouteiller";
      gitEmail = work;
    };
    vm = {
      user = let
        value = builtins.getEnv "VM_USER";
      in
        if value == ""
        then throw "Set VM_USER and evaluate with --impure"
        else value;
      gitEmail = work;
    };
    desktop.user = "antoinebouteiller";
    dell.user = "antoinebouteiller";
    plex-server.user = "antoineb";
  };
}
