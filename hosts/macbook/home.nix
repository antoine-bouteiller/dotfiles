{
  pkgs,
  config,
  ...
}: let
  inherit (config.home) homeDirectory;
in {
  local.home-manager.workstation.enable = true;
  local.home-manager.agents.claude-code.enable = true;

  home = {
    packages = [
      pkgs.dockutil
    ];
    stateVersion = "25.11";
  };

  home.sessionPath = [
    "${homeDirectory}/.npm-packages/bin"
  ];
  home.sessionVariables = {
    NODE_PATH = "${homeDirectory}/.npm-packages/lib/node_modules";
  };

  home.file.".npmrc".text = ''
    @work:registry=http://nexus.example.com/repository/npm/
    prefix=${homeDirectory}/.npm-packages
  '';

  manual.manpages.enable = false;
}
