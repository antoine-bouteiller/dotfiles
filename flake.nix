{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The `cachix` branch is the one upstream builds and pushes to noctalia.cachix.org.
    # Its nixpkgs is deliberately not followed: a different nixpkgs means a different
    # derivation hash, which would miss the cache and rebuild the whole C++ tree.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    autoscan = {
      url = "github:antoine-bouteiller/autoscan";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    meridian.url = "github:rynfar/meridian";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    # External Claude Code skills, pinned as non-flake sources.
    agent-browser-skill = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    globals = import ./globals.nix;
    libHelpers = import ./lib {inherit inputs globals self;};
    inherit (libHelpers) mkDarwinHost mkNixosHost;

    linuxSystems = ["x86_64-linux"];
    darwinSystems = ["aarch64-darwin"];
    allSystems = linuxSystems ++ darwinSystems;
    forAllSystems = f: nixpkgs.lib.genAttrs allSystems f;

    mkApp = scriptName: system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      type = "app";
      program = "${(pkgs.writeScriptBin scriptName ''
        #!${pkgs.bash}/bin/bash
        export PATH="${pkgs.bash}/bin:$PATH"
        echo "Running ${scriptName} for ${system}"
        exec ${self}/apps/${system}/${scriptName} "$@"
      '')}/bin/${scriptName}";
    };
    mkApps = system:
      {
        "apply" = mkApp "apply" system;
        "clean" = mkApp "clean" system;
        "update" = mkApp "update" system;
      }
      // nixpkgs.lib.optionalAttrs (builtins.elem system darwinSystems) {
        "apply-remote" = mkApp "apply-remote" system;
      }
      // nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) {
        "bootstrap" = mkApp "bootstrap" system;
        "noctalia-diff" = mkApp "noctalia-diff" system;
        "pin" = mkApp "pin" system;
        "secure-boot" = mkApp "secure-boot" system;
      };
  in {
    apps = nixpkgs.lib.genAttrs allSystems mkApps;

    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
        {
          comment-checker = pkgs.callPackage ./pkgs/comment-checker {};
          vite-plus = pkgs.callPackage ./pkgs/vite-plus {};
          claude-code = pkgs.callPackage ./pkgs/claude-code {};
          caddy-cloudflare = pkgs.callPackage ./pkgs/caddy-cloudflare {};
          fff-mcp = pkgs.callPackage ./pkgs/fff-mcp {};
          go-jls = pkgs.callPackage ./pkgs/go-jls {};
          pi = pkgs.callPackage ./pkgs/pi {};
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          nearby-file-share = pkgs.callPackage ./pkgs/nearby-file-share.nix {};
          helium = pkgs.callPackage ./pkgs/helium.nix {};

          install-iso = self.nixosConfigurations.iso.config.system.build.isoImage;
        }
        // nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          neostation = pkgs.callPackage ./pkgs/neostation {};
          ai-usagebar = pkgs.callPackage ./pkgs/ai-usagebar {};
        }
    );

    checks = forAllSystems (
      system: let
        darwinChecks = nixpkgs.lib.optionalAttrs (builtins.elem system darwinSystems) (
          # ponytail: CI omits the builder VM; restore coverage when CI has a Linux builder.
          nixpkgs.lib.mapAttrs (_: cfg:
            (cfg.extendModules {
              modules = [{nix.linux-builder.enable = nixpkgs.lib.mkForce false;}];
            }).system)
          self.darwinConfigurations
        );
        # `iso` is deliberately excluded: CI would build a full ISO on every push.
        # Include desktop once its on-device hardware configuration is tracked.
        nixosChecks = nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) (
          nixpkgs.lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel)
          (builtins.removeAttrs self.nixosConfigurations (
            ["iso"] ++ nixpkgs.lib.optional (!builtins.pathExists ./hosts/desktop/hardware-configuration.nix) "desktop"
          ))
        );
      in
        darwinChecks
        // nixosChecks
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          vm = self.homeConfigurations.vm.activationPackage;
        }
    );

    darwinConfigurations."lv6cfqjl6l-macos" = mkDarwinHost {
      name = "macbook";
      hostname = "lv6cfqjl6l-macos";
      system = "aarch64-darwin";
    };

    homeConfigurations.vm = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs globals;
        host = globals.hosts.vm;
        mkModule = import ./lib/module.nix nixpkgs.lib;
      };
      modules = [./hosts/vm/home.nix];
    };

    nixosConfigurations = {
      iso = mkNixosHost {
        hostname = "iso";
        system = "x86_64-linux";
      };

      plex-server = mkNixosHost {
        hostname = "plex-server";
        system = "x86_64-linux";
        extraModules = [inputs.autoscan.nixosModules.default];
      };

      desktop = mkNixosHost {
        hostname = "desktop";
        system = "x86_64-linux";
      };

      "antoine-dell" = mkNixosHost {
        name = "dell";
        hostname = "antoine-dell";
        system = "x86_64-linux";
        extraModules = [inputs.nixos-hardware.nixosModules.dell-xps-15-9500-nvidia];
      };
    };
  };
}
