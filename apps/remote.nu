#!/usr/bin/env nu
# Run on the VM with Nushell from the archived nixpkgs input.
use config.nu *

def check-user [expected_user: string] {
  if (^id -un | str trim) != $expected_user {
    error make {msg: 'SSH login must match the evaluated VM home username'}
  }
}

def 'main prepare' [expected_user: string] {
  check-user $expected_user
  ^sudo mkdir -p /etc/nix /etc/ssh/sshd_config.d
  (nix-config) + "\n" | ^sudo tee /etc/nix/dotfiles.conf out> /dev/null
  let config = ^sudo cat /etc/nix/nix.conf | complete
  if 'include dotfiles.conf' not-in ($config.stdout | lines) {
    "\ninclude dotfiles.conf\n" | ^sudo tee -a /etc/nix/nix.conf out> /dev/null
  }
  ^sudo systemctl restart nix-daemon
  "AcceptEnv SOPS_AGE_KEY\n" | ^sudo tee /etc/ssh/sshd_config.d/50-sops-age.conf out> /dev/null
  ^sudo systemctl reload ssh
}

def 'main activate' [expected_user: string, activation_drv: string, nh: string] {
  check-user $expected_user
  let result = ^nix build --no-link --json $"($activation_drv)^out" | from json
  ^$nh home switch ($result | get 0.outputs.out)
  ^$nh clean user --keep $generations_to_keep --keep-one
}

def main [] {
  error make {msg: 'Use prepare or activate via apply-remote.'}
}
