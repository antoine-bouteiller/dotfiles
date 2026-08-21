{
  lib,
  osConfig,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.zsh_history";
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
    };

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k-config;
        file = "p10k.zsh";
      }
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
      {
        name = "catppuccin-powerlevel10k-themes";
        src = pkgs.fetchFromGitHub {
          owner = "tolkonepiu";
          repo = "catppuccin-powerlevel10k-themes";
          rev = "6e72187953e5e9face7fbf8dcc926d691f7d1f2d";
          hash = "sha256-CMSsfW9gb0uawvBwRZNZMozectU95ORWQz+2S2WC+9Q=";
        };
        file = "catppuccin-powerlevel10k-themes.plugin.zsh";
      }
    ];

    shellAliases = {
      "_" = "sudo";
      l = "ls";
      cat = "bat";
      ll = "ls -lh";
      la = "ls -lAh";
      ldot = "ls -ld .*";
      quit = "exit";
      "cd.." = "cd ..";
      tarls = "tar -tvf";
      untar = "tar -xf";
      bua = "bup && bcup --greedy && bcn";
      please = "sudo";
      zshrc = "\${EDITOR:-nvim} $HOME/.zshrc";
      zdot = "cd ${osConfig.flakePath}";
    };

    envExtra = ''
      export XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
      export XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}
      export XDG_CACHE_HOME=''${XDG_CACHE_HOME:-$HOME/.cache}
      typeset -gU path fpath
    '';

    profileExtra = ''
      # OrbStack integration
      [[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh 2>/dev/null || :
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 850 ''
        # Configure Catppuccin before Home Manager loads the theme plugin.
        zstyle ':catppuccin:p10k' theme rainbow
        ${
          if pkgs.stdenv.hostPlatform.isDarwin
          then ''
            typeset -g _p10k_catppuccin_flavour=latte
            defaults read -g AppleInterfaceStyle &>/dev/null && _p10k_catppuccin_flavour=mocha
            zstyle ':catppuccin:p10k' flavour "$_p10k_catppuccin_flavour"
          ''
          else ''
            zstyle ':catppuccin:p10k' flavour mocha
          ''
        }
      '')
      (lib.mkOrder 1000 ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        # PATH setup
        export path=(
          $HOME/{,s}bin(N)
          $HOME/.cache/.bun/bin(N)
          $HOME/.local/{,s}bin(N)
          /opt/{homebrew,local}/{,s}bin(N)
          /usr/local/{,s}bin(N)
          $path
        )

        # History substring key binding
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^[OA' history-substring-search-up
        bindkey '^[OB' history-substring-search-down

        # Completion styles
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'

        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          _p10k_catppuccin_autoswitch() {
            local flavour=latte
            defaults read -g AppleInterfaceStyle &>/dev/null && flavour=mocha
            [[ $flavour == $_p10k_catppuccin_flavour ]] && return
            typeset -g _p10k_catppuccin_flavour=$flavour
            apply_catppuccin rainbow "$flavour"
          }
          autoload -Uz add-zsh-hook
          add-zsh-hook precmd _p10k_catppuccin_autoswitch
        ''}

        # Source local/work config
        [[ -f ${osConfig.flakePath}/.zlocal ]] && source ${osConfig.flakePath}/.zlocal
      '')
    ];
  };
}
