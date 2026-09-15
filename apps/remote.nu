#!/usr/bin/env nu
# Run on the VM with Nushell from the archived nixpkgs input.
use config.nu nix-config

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

def 'main activate' [expected_user: string, public_source: string, private_source: string] {
  check-user $expected_user
  let out = ^nix build --no-link --print-out-paths $"($public_source)#homeConfigurations.vm.activationPackage" --no-write-lock-file --override-input privateConfig $"path:($private_source)" | str trim
  ^($out | path join activate)
}

def main [] {
  error make {msg: 'Use prepare or activate via apply-remote.'}
}
