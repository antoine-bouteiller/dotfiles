{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (config.home) homeDirectory;
in {
  local.home-manager.workstation.enable = true;

  programs.mcp.servers = lib.mkIf config.local.home-manager.agents.enable {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
      headers.Authorization = "Bearer \${LINEAR_TOKEN}";
    };
    slack = {
      type = "http";
      url = "https://mcp.slack.com/mcp";
      oauth = {
        clientId = "1601185624273.8899143856786";
        callbackPort = 3118;
      };
    };
    dbx-mcp = {
      command = "dbx-mcp-server";
    };
    figma = {
      url = "https://mcp.figma.com/mcp";
      type = "http";
      "oauth" = {
        clientName = "Claude Code";
        scope = "mcp:connect";
      };
    };
  };

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
