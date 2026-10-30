{
  mkModule,
  inputs,
  pkgs,
  config,
  lib,
  ...
} @ args: let
  cfg = config.local.home-manager.rex;
  appPackage = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.rex;
  # The app bundles the CLI.
  package =
    if cfg.client.enable
    then appPackage
    else config.programs.rex.package;
  agents = config.local.home-manager.agents;
  claude = agents.enable && agents.claude-code.enable;
  inherit (import ../../../../lib/palette.nix {inherit lib;}) colors hexToRgb;

  themeId = "custom-dotfiles";
  color = hex: let
    c = map (v: v / 255.0) (hexToRgb hex);
  in {
    red = builtins.elemAt c 0;
    green = builtins.elemAt c 1;
    blue = builtins.elemAt c 2;
    alpha = 1;
    colorSpace = "srgb";
  };
  # Same shape the app writes for a theme created in its settings.
  themes = pkgs.writeText "rex-themes.json" (builtins.toJSON [
    {
      id = themeId;
      name = "Dotfiles";
      appearance = "dark";
      createdAt = 0;
      source.manual = {};
      palette = {
        background = color colors.background;
        foreground = color colors.text;
        cursor = color colors.text;
        cursorText = color colors.background;
        selectionBackground = color colors.surfaceHover;
        selectionForeground = color colors.text;
        ansi = map color (with colors; [
          backgroundDark
          red
          green
          yellow
          blue
          magenta
          cyan
          textMuted
          textFaint
          red
          green
          yellow
          blue
          magenta
          cyan
          text
        ]);
        paletteGenerate = false;
        paletteHarmonious = false;
        paletteBase = {};
        paletteOverrides = {};
      };
    }
  ]);

  # The upstream stub skill defers to `rex __internal skill`, so it tracks the installed CLI.
  skill = pkgs.runCommand "rex-agent-skill" {} ''
    export HOME=$TMPDIR
    ${lib.getExe package} skill setup --agent claude --session-naming --autostart=false >/dev/null
    cp -R $HOME/.claude/skills/rex $out
  '';
in
  mkModule args "local.home-manager.rex" {
    description = "Rex CLI and config";
    imports = [inputs.rex.homeManagerModules.default];

    options = {
      client.enable = lib.mkEnableOption "the Rex app, which also runs a server while open";
      # Without it, the first rex command starts a server that exits after its last session.
      server.enable = lib.mkEnableOption "a persistent Rex server as a systemd user service";
      hosts = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {};
        example = {studio = ["unix:///tmp/rex-studio.sock"];};
        description = "Rex hosts by label, each reached at its endpoints in turn.";
      };
    };

    config = _: {
      assertions = [
        {
          assertion = cfg.client.enable -> pkgs.stdenv.hostPlatform.isDarwin;
          message = "local.home-manager.rex.client packages the macOS app only.";
        }
      ];

      programs.rex = {
        enable = true;
        # The app's CLI comes without the terminfo entry and ssh guard this module installs.
        package = lib.mkIf cfg.client.enable null;
      };
      services.rex.enable = cfg.server.enable;

      home.packages = lib.mkIf cfg.client.enable [appPackage];

      # Sparkle would replace the Nix-managed app with a version the store CLI doesn't match.
      targets.darwin.defaults."com.superlogical.rex" = lib.mkIf cfg.client.enable {
        SUEnableAutomaticChecks = false;
        "Workspace.darkThemeID" = themeId;
      };

      # Rex reads custom themes as JSON in a data value, which targets.darwin.defaults cannot
      # write. This replaces any theme created in the app.
      home.activation.rexTheme = lib.mkIf cfg.client.enable (lib.hm.dag.entryAfter ["writeBoundary"] ''
        run /usr/bin/defaults write com.superlogical.rex Workspace.customThemes \
          -data "$(/usr/bin/xxd -p ${themes} | /usr/bin/tr -d '\n')"
      '');

      xdg.configFile."rex/init.lua" = {
        text =
          builtins.readFile ./init.lua
          + lib.concatStrings (lib.mapAttrsToList (label: endpoints: ''

              rex.host(${lib.generators.toLua {} {inherit label endpoints;}})
            '')
            cfg.hosts);
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
