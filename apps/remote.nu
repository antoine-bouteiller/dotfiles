#!/usr/bin/env nu
# Run on the VM with Nushell from the archived nixpkgs input.
use config.nu *

def check-user [expected_user: string] {
  if (^id -un | str trim) != $expected_user {
    error make {msg: 'SSH login must match the evaluated VM home username'}
  }
}

def 'main prepare' [expected_user: string, nix: string] {
  check-user $expected_user
  ^sudo mkdir -p /etc/nix /etc/ssh/sshd_config.d

  # Keep profile generations for rollback; the system profile owns Nix and CA roots.
  let profile = '/nix/var/nix/profiles/default'
  if (^readlink -f $profile | str trim) != $nix {
    ^sudo $"($nix)/bin/nix-env" --profile $profile --set $nix
  }

  # Retire Determinate's service, not its store or user profiles. Its generated config
  # is disposable; preserve it for rollback and continue including user overrides.
  if ('/etc/systemd/system/determinate-nixd.socket' | path exists) {
    let backup = '/etc/nix/before-dotfiles'
    ^sudo install -d -m 700 $backup
    for file in [/etc/nix/nix.conf /etc/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.socket /etc/systemd/system/determinate-nixd.socket] {
      if (^sudo test -e ($backup | path join ($file | path basename)) | complete).exit_code != 0 {
        ^sudo cp --dereference $file $backup
      }
    }
    ^sudo systemctl disable --now determinate-nixd.socket
    ^sudo systemctl stop nix-daemon.service nix-daemon.socket
    "!include nix.custom.conf\n" | ^sudo tee /etc/nix/nix.conf out> /dev/null
    ^sudo rm /etc/systemd/system/determinate-nixd.socket
  }

  "build-users-group = nixbld\n" + (nix-config) + "\n" | ^sudo tee /etc/nix/dotfiles.conf out> /dev/null
  let config = ^sudo cat /etc/nix/nix.conf | complete
  if 'include dotfiles.conf' not-in ($config.stdout | lines) {
    "\ninclude dotfiles.conf\n" | ^sudo tee -a /etc/nix/nix.conf out> /dev/null
  }
  for unit in [nix-daemon.service nix-daemon.socket] {
    ^sudo ln -sfn $"($profile)/lib/systemd/system/($unit)" $"/etc/systemd/system/($unit)"
  }
  ^sudo systemctl daemon-reload
  ^sudo systemctl enable --now nix-daemon.socket
  ^sudo systemctl restart nix-daemon.service
  "AcceptEnv SOPS_AGE_KEY\n" | ^sudo tee /etc/ssh/sshd_config.d/50-sops-age.conf out> /dev/null
  ^sudo systemctl reload ssh
}

def 'main activate' [expected_user: string, activation_drv: string, nh: string, root: string] {
  check-user $expected_user
  let result = ^/nix/var/nix/profiles/default/bin/nix build --out-link $root --json $"($activation_drv)^out" | from json
  ^$nh home switch ($result | get 0.outputs.out)
  ^$nh clean user --keep $generations_to_keep --keep-one
}

def main [] {
  error make {msg: 'Use prepare or activate via apply-remote.'}
}
