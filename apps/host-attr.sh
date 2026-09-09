# Flake attrs are short host names while hostnames stay network-discoverable, so the
# `.#$(hostname)` default of nh/nixos-rebuild/darwin-rebuild does not resolve.
# host_attr nixos|darwin -> the attr whose networking.hostName is this machine.
host_attr() {
  nix eval --raw ".#${1}Configurations" --apply \
    "cfgs: builtins.head (builtins.filter (n: cfgs.\${n}.config.networking.hostName == \"$(hostname -s)\") (builtins.attrNames cfgs))"
}
