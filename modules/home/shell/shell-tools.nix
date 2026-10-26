{
  config,
  inputs,
  mkModule,
  pkgs,
  ...
} @ args: let
  zoxideInit = pkgs.runCommand "zoxide-init.zsh" {} ''
    ${pkgs.zoxide}/bin/zoxide init zsh --cmd cd > $out
  '';
  # Hooks embed the invoking path; use the profile path so open shells survive GC.
  profileBin = "${config.home.profileDirectory}/bin";
  direnvInit = pkgs.runCommand "direnv-init.zsh" {} ''
    ${pkgs.direnv}/bin/direnv hook zsh \
      | sed 's|${pkgs.direnv}/bin/direnv|${profileBin}/direnv|' > $out
  '';
  carapaceInit = pkgs.runCommand "carapace-init.zsh" {} ''
    ${pkgs.carapace}/bin/carapace _carapace zsh > $out
  '';
  # `corepack enable` defaults to writing next to node, which is read-only in the store.
  corepackShims = pkgs.runCommand "corepack-shims" {} ''
    mkdir -p $out/bin
    ${pkgs.nodejs}/bin/corepack enable --install-directory $out/bin
  '';
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in
  mkModule args "local.home-manager.shell-tools" {
    description = "shell tools (zoxide, direnv, carapace, mise)";
    config = _: {
      home.packages = [
        customPkgs.bun
        customPkgs.vite-plus
        pkgs.nodejs
        corepackShims
        pkgs.python3
        pkgs.uv
      ];

      programs = {
        zoxide = {
          enable = true;
          enableZshIntegration = false;
          options = [
            "--cmd"
            "cd"
          ];
        };

        carapace = {
          enable = true;
          enableZshIntegration = false;
        };

        direnv = {
          enable = true;
          enableZshIntegration = false;
        };

        mise = {
          enable = true;
          enableZshIntegration = false;
        };

        zsh.envExtra = ''
          export CARAPACE_BRIDGES='zsh,bash'
        '';

        zsh.initContent = ''
          if [[ -o interactive ]]; then
            source ${zoxideInit}
          fi
          source ${direnvInit}
          eval "$(${profileBin}/mise activate zsh)"
          source ${carapaceInit}
        '';
      };
    };
  }
