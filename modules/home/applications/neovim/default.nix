{
  config,
  lib,
  pkgs,
  ...
}: {
  options.local.home-manager.neovim.lazyvimExtras = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "LazyVim extras enabled in lazyvim.json.";
  };

  config = {
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    programs.neovim = {
      enable = true;
      withPython3 = false;
      withRuby = false;
      vimAlias = true;
      viAlias = true;
      # nvim-treesitter (main) needs the tree-sitter CLI; mason's prebuilt one requires a newer glibc than the standalone HM host.
      extraPackages = with pkgs; [
        stdenv.cc
        tree-sitter
        git
        ripgrep
        fd
        fzf
        curl
        gnutar
        gzip
        unzip
        bash
        nixd
        alejandra
        statix
        ty
        ruff
        rust-analyzer
        vscode-langservers-extracted
        yaml-language-server
        svelte-language-server
      ];
      # Absolute paths: extraPackages are appended to PATH, so another tsc (e.g. TypeScript 5) would win.
      initLua = ''
        vim.g.nix_tsc = "${lib.getExe' pkgs.typescript "tsc"}"
        vim.g.nix_fff_dir = "${pkgs.vimPlugins.fff-nvim}"
        require("config.lazy")
      '';
    };

    local.home-manager.neovim.lazyvimExtras = [
      "lazyvim.plugins.extras.editor.neo-tree"
      "lazyvim.plugins.extras.lang.json"
      "lazyvim.plugins.extras.lang.nix"
      "lazyvim.plugins.extras.lang.python"
      "lazyvim.plugins.extras.lang.rust"
      "lazyvim.plugins.extras.lang.typescript"
      "lazyvim.plugins.extras.lang.yaml"
    ];

    programs.zsh.shellAliases.n = "nvim .";

    xdg.configFile = {
      "nvim/lua/config/autocmds.lua".source = ./lazyvim/lua/config/autocmds.lua;
      "nvim/lua/config/lazy.lua".source = ./lazyvim/lua/config/lazy.lua;
      "nvim/lua/config/options.lua".source = ./lazyvim/lua/config/options.lua;
      "nvim/lua/config/remote_clipboard.lua".source = ./lazyvim/lua/config/remote_clipboard.lua;
      "nvim/lua/plugins/disable-news-alert.lua".source = ./lazyvim/lua/plugins/disable-news-alert.lua;
      "nvim/lua/plugins/catppuccin.lua".source = ./lazyvim/lua/plugins/catppuccin.lua;
      "nvim/lua/plugins/fff.lua".source = ./lazyvim/lua/plugins/fff.lua;
      "nvim/lua/plugins/lsp.lua".source = ./lazyvim/lua/plugins/lsp.lua;
      "nvim/lua/plugins/nix.lua".source = ./lazyvim/lua/plugins/nix.lua;
      "nvim/lua/plugins/snacks-animated-scrolling-off.lua".source = ./lazyvim/lua/plugins/snacks-animated-scrolling-off.lua;
      "nvim/plugin/after/transparency.lua".source = ./lazyvim/plugin/after/transparency.lua;
      "nvim/lazyvim.json".text = builtins.toJSON {
        extras = config.local.home-manager.neovim.lazyvimExtras;
        install_version = 8;
        news."NEWS.md" = "10960";
        version = 8;
      };
    };
  };
}
