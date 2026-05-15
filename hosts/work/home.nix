{
  globals,
  pkgs,
  config,
  ...
}: let
  inherit (config.home) homeDirectory;
in {
  imports = [
    ../../home-manager
  ];

  local.home-manager = {
    zed.enable = true;
    claudeCode = {
      enable = true;
    };
    tmux.enable = true;
  };

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [pkgs.dockutil];
    stateVersion = "25.11";
  };

  home.sessionPath = [
    "${homeDirectory}/.npm-packages/bin"
  ];
  home.sessionVariables = {
    NODE_PATH = "${homeDirectory}/.npm-packages/lib/node_modules";
  };

  programs.git = {
    settings.user.email = (let value = builtins.getEnv "WORK_EMAIL"; in if value == "" then throw "Set WORK_EMAIL and evaluate with --impure" else value);
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@github.com:*/**";
        path = "~/.gitconfig-github";
      }
      {
        condition = "hasconfig:remote.*.url:https://github.com/**";
        path = "~/.gitconfig-github";
      }
    ];
  };

  home.file.".gitconfig-github" = {
    text = ''
      [user]
        email = ${globals.email}
    '';
  };

  home.file.".npmrc".text = ''
    @work:registry=http://nexus.example.com/repository/npm/
    prefix=${homeDirectory}/.npm-packages
  '';

  manual.manpages.enable = false;
}
