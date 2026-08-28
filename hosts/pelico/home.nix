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
    ghostty.enable = true;
    herdr.enable = true;
    hunk.enable = true;
    shell-tools.enable = true;
    agents = {
      enable = true;
      claude-code.enable = true;
      pi.enable = true;
      mcpServers = {
        linear = {
          type = "http";
          url = "https://mcp.linear.app/mcp";
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
    };
    runenv = {
      enable = true;
      secretsDir = "${homeDirectory}/.dotfiles/hosts/pelico/secrets";
    };
  };

  home = {
    enableNixpkgsReleaseCheck = false;
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
    prefix=${homeDirectory}/.npm-packages
  '';

  manual.manpages.enable = false;
}
