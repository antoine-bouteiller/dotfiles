{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.home) homeDirectory;
  inherit (pkgs.stdenv) isDarwin;
  claudeDir = "${homeDirectory}/.dotfiles/home-manager/applications/claude-code";
  mcpPort = "3050";

  oneMcpConfig = builtins.toJSON {
    mcpServers = {
      context7 = {
        type = "stdio";
        disabled = false;
        command = "npx";
        args = ["-y" "@upstash/context7-mcp"];
      };
      devtools = {
        type = "stdio";
        disabled = false;
        command = "npx";
        args = ["-y" "firefox-devtools-mcp@latest"];
      };
      linear = {
        type = "http";
        url = "https://mcp.linear.app/mcp";
        disabled = false;
      };
      notion = {
        type = "http";
        url = "https://mcp.notion.com/mcp";
        disabled = false;
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp";
        headers = {
          Authorization = "Bearer ${config.sops.placeholder.github_pat}";
        };
        disabled = false;
      };
    };
  };
in
  lib.mkMerge [
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.claude-code;

        context = "${claudeDir}/CLAUDE.md";

        mcpServers = {
          "1mcp" = {
            type = "http";
            url = "http://127.0.0.1:${mcpPort}/mcp?app=claude-code";
          };
        };

        hooksDir = "${./hooks}";
        rulesDir = "${./rules}";
      };

      sops.templates."1mcp-config".content = oneMcpConfig;

      home.file = {
        ".claude/settings.json".source = mkOutOfStoreSymlink "${claudeDir}/settings.json";
      };
    }
    (lib.mkIf isDarwin {
      launchd.agents."1mcp" = {
        enable = true;
        config = {
          Label = "fr.antoinebouteiller.1mcp";
          ProgramArguments = ["${customPkgs._1mcp}/bin/1mcp" "--enable-auth" "--config" config.sops.templates."1mcp-config".path];
          EnvironmentVariables = {
            PATH = lib.makeBinPath [pkgs.nodejs_24 pkgs.coreutils pkgs.bash];
          };
          RunAtLoad = true;
          StandardOutPath = "${homeDirectory}/Library/Logs/1mcp.log";
          StandardErrorPath = "${homeDirectory}/Library/Logs/1mcp.error.log";
        };
      };
    })
  ]
