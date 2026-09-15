# Local private-configuration helpers.

export def git-ref [path: string]: nothing -> string {
  let encoded = ($path | url encode --all | str replace -a '%2F' '/')
  $"git+file://($encoded)"
}

def fail [message: string] {
  error make {msg: $"private configuration error: ($message)"}
}

# Nushell exposes an exported `main` under the module name, so callers use this
# module as `private-config`. (An export literally named private-config is invalid.)
# Returns the public checkout and optional local privateConfig input override.
export def main []: nothing -> record<root: string, public_ref: string, nix_args: list<string>> {
  let root_result = (^git rev-parse --show-toplevel | complete)
  if $root_result.exit_code != 0 {
    fail 'run this command from a Git checkout'
  }
  let root = ($root_result.stdout | str trim)
  let private_root = $"($root)/.private"
  mut nix_args = [--no-write-lock-file]

  # `path type` reports a broken symlink as a symlink, unlike a normal exists check.
  let private_type: any = ($private_root | path type)
  if $private_type == null {
    return {root: $root, public_ref: (git-ref $root), nix_args: $nix_args}
  }
  if $private_type == 'symlink' {
    fail '.private must not be a symlink'
  }
  if $private_type != 'dir' {
    fail '.private must be an independent Git repository'
  }

  let git_root_result = (^git -C $private_root rev-parse --show-toplevel | complete)
  if $git_root_result.exit_code != 0 {
    fail '.private must be an independent Git repository'
  }
  let private_physical = ($private_root | path expand --strict)
  let git_physical = ($git_root_result.stdout | str trim | path expand --strict)
  if $private_physical != $git_physical {
    fail '.private must be an independent Git repository'
  }

  for entry in [default.nix home.nix] {
    let entry_path = $"($private_root)/($entry)"
    if ($entry_path | path exists) {
      let tracked = (^git -C $private_root ls-files --error-unmatch -- $entry | complete)
      if $tracked.exit_code != 0 {
        fail $".private/($entry) exists but is not tracked; stage it before applying"
      }
    }
  }
  $nix_args = $nix_args ++ [--override-input privateConfig (git-ref $private_root)]
  {root: $root, public_ref: (git-ref $root), nix_args: $nix_args}
}

# Flake attrs are short host names, unlike network-discoverable hostnames.
export def host-attr [kind: string, config: record]: nothing -> string {
  let validation = match $kind {
    darwin => 'cfg.system.drvPath'
    nixos => 'cfg.config.system.build.toplevel.drvPath'
    _ => { error make {msg: $"unknown configuration kind: ($kind)"} }
  }
  let hostname = (^hostname -s | str trim)
  let hostname_literal = ($hostname | to json -r)
  let apply = ('cfgs: let name = builtins.head (builtins.filter (n: cfgs.${n}.config.networking.hostName == ' + $hostname_literal + ') (builtins.attrNames cfgs)); cfg = cfgs.${name}; in builtins.seq (' + $validation + ') name')
  ^nix eval --raw $"($config.public_ref)#($kind)Configurations" --apply $apply ...$config.nix_args | str trim
}

export def split-nh-args [args: list<string>]: nothing -> record<nh_args: list<string>, nix_args: list<string>> {
  let nh_args = $args | take until {|arg| $arg == '--' }
  {nh_args: $nh_args, nix_args: ($args | skip (($nh_args | length) + 1))}
}
