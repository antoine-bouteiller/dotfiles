_: {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    initLua = ''
      require("config.lazy")
    '';
  };

  programs.zsh.shellAliases.n = "nvim .";

  xdg.configFile = {
    "nvim/lua/config/lazy.lua".source = ./lazyvim/lua/config/lazy.lua;
    "nvim/lua/config/options.lua".source = ./lazyvim/lua/config/options.lua;
    "nvim/lua/config/remote_clipboard.lua".source = ./lazyvim/lua/config/remote_clipboard.lua;
    "nvim/lua/plugins/disable-news-alert.lua".source = ./lazyvim/lua/plugins/disable-news-alert.lua;
    "nvim/lua/plugins/snacks-animated-scrolling-off.lua".source = ./lazyvim/lua/plugins/snacks-animated-scrolling-off.lua;
    "nvim/plugin/after/transparency.lua".source = ./lazyvim/plugin/after/transparency.lua;
    "nvim/lazyvim.json".source = ./lazyvim/lazyvim.json;
    "nvim/lazy-lock.json".source = ./lazyvim/lazy-lock.json;
  };
}
