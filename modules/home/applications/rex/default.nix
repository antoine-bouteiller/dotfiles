{
  mkModule,
  inputs,
  pkgs,
  config,
  lib,
  ...
} @ args: let
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.rex;
  agents = config.local.home-manager.agents;
  claude = agents.enable && agents.claude-code.enable;

  # The upstream stub skill defers to `rex __internal skill`, so it tracks the installed CLI.
  skill = pkgs.runCommand "rex-agent-skill" {} ''
    export HOME=$TMPDIR
    ${lib.getExe package} skill setup --agent claude --session-naming --autostart=false >/dev/null
    cp -R $HOME/.claude/skills/rex $out
  '';
in
  mkModule args "local.home-manager.rex" {
    description = "Rex terminal multiplexer app";

    config = _: {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "local.home-manager.rex ships the macOS app only.";
        }
      ];

      home.packages = [package];

      # Sparkle would replace the Nix-managed app with a version the store CLI doesn't match.
      targets.darwin.defaults."com.superlogical.rex".SUEnableAutomaticChecks = false;

      xdg.configFile."rex/init.lua" = {
        source = ./init.lua;
        onChange = "${lib.getExe package} config reload --autostart=false >/dev/null 2>&1 || true";
      };

      home.file =
        lib.optionalAttrs agents.enable {".agents/skills/rex".source = skill;}
        // lib.optionalAttrs claude {".claude/skills/rex".source = skill;};

      # Same hook `rex skill setup` writes, which it cannot add to the store-managed settings.json.
      programs.claude-code.settings.hooks.SessionStart = lib.mkIf claude [
        {
          hooks = [
            {
              type = "command";
              command = "/bin/sh -c 'rex __internal session-start --agent claude 2>/dev/null || true'";
              timeout = 5;
            }
          ];
        }
      ];
    };
  }
