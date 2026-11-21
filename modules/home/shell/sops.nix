{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops.age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

  # The upstream urfave/cli completion offers files only when no subcommand matches, so
  # `sops <TAB>` never lists files even though `sops <file>` edits it.
  programs.zsh.initContent = ''
    _sops_files() {
      local -a opts
      local cur=''${words[-1]}
      if [[ $cur == -* ]]; then
        opts=("''${(@f)$(_CLI_ZSH_AUTOCOMPLETE_HACK=1 ''${words[@]:0:#words[@]-1} $cur --generate-bash-completion)}")
      else
        opts=("''${(@f)$(_CLI_ZSH_AUTOCOMPLETE_HACK=1 ''${words[@]:0:#words[@]-1} --generate-bash-completion)}")
      fi
      [[ -n ''${opts[1]} ]] && _describe 'values' opts
      [[ $cur == -* ]] || _files
    }
    compdef _sops_files sops
  '';
}
