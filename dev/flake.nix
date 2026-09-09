{
  description = "Dotfiles development tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    treefmt-nix,
    git-hooks,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs ["aarch64-darwin" "x86_64-linux"];
    formatter = forAllSystems (
      system: (treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix).config.build.wrapper
    );
  in {
    inherit formatter;
    packages = forAllSystems (system: {default = formatter.${system};});

    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        preCommit = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            treefmt = {
              enable = true;
              package = formatter.${system};
            };
            gitleaks = {
              enable = true;
              name = "gitleaks";
              package = pkgs.gitleaks;
              entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged --config .gitleaks.toml";
              pass_filenames = false;
            };
          };
        };
      in {
        default = pkgs.mkShellNoCC {
          inherit (preCommit) shellHook;
          packages = preCommit.enabledPackages;
        };
      }
    );
  };
}
