# go-jls is owned by Zed, not agents, on both platforms (AC-006).
# Run: nix eval --impure --json --file tests/review-fixes-zed.nix
let
  flake = builtins.getFlake (toString ./..);
  inherit (flake.inputs.nixpkgs) lib;
  inherit (import ../globals.nix) user;

  hasGoJls = host: zed: agents: let
    extended = host.extendModules {
      modules = [
        {
          home-manager.users.${user}.local.home-manager = {
            zed.enable = lib.mkForce zed;
            agents.enable = lib.mkForce agents;
          };
        }
      ];
    };
    packages = extended.config.home-manager.users.${user}.home.packages;
  in
    builtins.any (p: (p.pname or "") == "go-jls") packages;

  hosts = {
    darwin = flake.darwinConfigurations."lv6cfqjl6l-macos";
    desktop = flake.nixosConfigurations.desktop;
  };

  results =
    lib.mapAttrs (_: host: {
      zedOnly = hasGoJls host true false;
      agentsOnly = hasGoJls host false true;
    })
    hosts;
in
  assert lib.all (r: r.zedOnly && !r.agentsOnly) (lib.attrValues results); results
