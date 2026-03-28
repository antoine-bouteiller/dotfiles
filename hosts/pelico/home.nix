{
  globals,
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../home-manager/common.nix
    ../../home-manager/applications/ghostty.nix
    ../../home-manager/applications/vim.nix
    ../../home-manager/applications/zed
    ../../home-manager/applications/claude-code
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    packages = [pkgs.dockutil];
    stateVersion = "25.11";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-packages/bin"
  ];
  home.sessionVariables = {
    NODE_PATH = "${config.home.homeDirectory}/.npm-packages/lib/node_modules";
  };

  programs.git = {
    settings.user.email = "antoine.bouteiller@pelico.io";
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
    @pelico:registry=http://nexus.pelico.best/repository/npm/
    prefix=${config.home.homeDirectory}/.npm-packages
  '';

  manual.manpages.enable = false;
}
