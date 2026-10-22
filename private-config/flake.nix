{
  description = "Empty public stand-in for the private configuration flake";

  # Mirrors the private flake's inputs so the root flake's follows resolves.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = _: {
    homeModules.default = {};
    hosts = {};
  };
}
