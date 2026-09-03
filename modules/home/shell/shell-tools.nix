{
  mkModule,
  pkgs,
  inputs,
  ...
} @ args: let
  zoxideInit = pkgs.runCommand "zoxide-init.zsh" {} ''
    ${pkgs.zoxide}/bin/zoxide init zsh --cmd cd > $out
  '';
  direnvInit = pkgs.runCommand "direnv-init.zsh" {} ''
    ${pkgs.direnv}/bin/direnv hook zsh > $out
  '';
  carapaceInit = pkgs.runCommand "carapace-init.zsh" {} ''
    ${pkgs.carapace}/bin/carapace _carapace zsh > $out
  '';
  miseInit = pkgs.runCommand "mise-init.zsh" {} ''
    ${pkgs.mise}/bin/mise activate zsh > $out
  '';
in
  mkModule args "local.home-manager.shell-tools" {
    description = "shell tools (zoxide, direnv, carapace, mise, treefmt)";
    config = _: {
      # Same treefmt wrapper `nix fmt` uses (config baked in), so `treefmt` works anywhere.
      home.packages = [inputs.self.formatter.${pkgs.stdenv.hostPlatform.system}];

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
          source ${carapaceInit}
          source ${miseInit}
        '';
      };
    };
  }
