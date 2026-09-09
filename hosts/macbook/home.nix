{
  globals,
  pkgs,
  config,
  ...
}: let
  inherit (config.home) homeDirectory;
  vmHosts = "*.example.com";
in {
  imports = [
    ../../modules/home
  ];

  local.home-manager = {
    workstation.enable = true;
    # The work VM's sshd accepts SOPS_AGE_KEY (see apps/*/apply-remote).
    herdr.sopsAgeKeyHosts = [vmHosts];
    agents = {
      pi.extraSecretFiles = ["${homeDirectory}/.dotfiles/secrets/work_env.yaml"];
      mcpServers = {
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
    };
    runenv = {
      enable = true;
      secretsDir = "${homeDirectory}/.dotfiles/secrets";
      defaultNamespace = "work_env";
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

  # git+ssh on the VM uses this machine's key through agent forwarding, like apply-remote's `ssh -A`.
  # The launchd ssh-agent starts empty: AddKeysToAgent loads id_ed25519 into it on
  # first use (declarative `ssh-add`), so there is a key to forward.
  programs.ssh.settings = {
    "*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    };
    ${vmHosts}.ForwardAgent = true;
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
