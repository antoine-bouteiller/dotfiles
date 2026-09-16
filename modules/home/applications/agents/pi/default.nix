{
  mkModule,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};

  secretFiles = ["${config.local.home-manager.sourcePath}/secrets/agent.yaml"] ++ agents.pi.extraSecretFiles;

  # pi runs with the agent API keys decrypted into its own process only.
  # sops exec-env takes one file, so each extra file wraps the command in another layer.
  piWrapped = pkgs.writeShellScriptBin "pi" ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''export ${name}=''${${name}:-${lib.escapeShellArg value}}'') agents.pi.env)}
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-${config.home.homeDirectory}/.config/sops/age/keys.txt}"
    cmd="${lib.getExe customPkgs.pi} $(printf '%q ' "$@")"
    for f in ${lib.escapeShellArgs secretFiles}; do
      cmd="${lib.getExe pkgs.sops} exec-env $f $(printf '%q' "$cmd")"
    done
    eval exec "$cmd"
  '';

  mocha = (import ../../../../../lib/palette.nix {inherit lib;}).colors;
  theme = {
    name = "catppuccin-mocha";
    vars = mocha;
    export = {
      pageBg = mocha.crust;
      cardBg = mocha.base;
      infoBg = mocha.surface0;
    };
    colors = {
      accent = "mauve";
      border = "surface2";
      borderAccent = "lavender";
      borderMuted = "surface1";
      success = "green";
      error = "red";
      warning = "yellow";
      muted = "subtext0";
      dim = "overlay1";
      text = "text";
      thinkingText = "subtext1";
      selectedBg = "surface0";
      userMessageBg = "surface0";
      userMessageText = "text";
      customMessageBg = "mantle";
      customMessageText = "text";
      customMessageLabel = "mauve";
      toolPendingBg = "mantle";
      toolSuccessBg = "surface0";
      toolErrorBg = "surface0";
      toolTitle = "blue";
      toolOutput = "overlay2";
      mdHeading = "mauve";
      mdLink = "blue";
      mdLinkUrl = "sapphire";
      mdCode = "peach";
      mdCodeBlock = "subtext1";
      mdCodeBlockBorder = "surface2";
      mdQuote = "subtext0";
      mdQuoteBorder = "surface2";
      mdHr = "surface2";
      mdListBullet = "mauve";
      toolDiffAdded = "green";
      toolDiffRemoved = "red";
      toolDiffContext = "subtext0";
      syntaxComment = "overlay2";
      syntaxKeyword = "mauve";
      syntaxFunction = "blue";
      syntaxVariable = "maroon";
      syntaxString = "green";
      syntaxNumber = "peach";
      syntaxType = "yellow";
      syntaxOperator = "sky";
      syntaxPunctuation = "overlay2";
      thinkingOff = "surface1";
      thinkingMinimal = "surface2";
      thinkingLow = "blue";
      thinkingMedium = "sapphire";
      thinkingHigh = "mauve";
      thinkingXhigh = "red";
      bashMode = "peach";
    };
  };
in
  mkModule args "local.home-manager.agents.pi" {
    description = "pi with declarative settings and themes";
    imports = [./meridian.nix];

    options.env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Default environment variables for pi; existing non-empty values take precedence.";
    };

    options.extraSecretFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional sops files decrypted into pi's environment, alongside secrets/agent.yaml.";
    };

    config = _:
      lib.mkIf agents.enable {
        programs.pi-coding-agent = {
          enable = true;
          package = piWrapped;
          context = ./AGENTS.md;
          settings = {
            lastChangelogVersion = "0.85.1";
            theme = theme.name;
            defaultProvider = "azure-openai-responses";
            defaultModel = "gpt-6-astra";
            enabledModels = [
              "azure-openai-responses/gpt-6-astra"
              "anthropic/claude-sonnet-5"
              "anthropic/claude-opus-5"
              "anthropic/claude-fable-5-1"
            ];
            packages = [
              "npm:@ff-labs/pi-fff"
              "git:github.com/antoine-bouteiller/pi-extensions"
              "git:github.com/antoine-bouteiller/plan-viewer"
            ];
            npmCommand = [
              "bun"
            ];
            defaultThinkingLevel = "medium";
            tuiMode = "fullscreen";
            subagents = {
              implementer = "azure-openai-responses/gpt-5.6-terra";
              librarian = "azure-openai-responses/gpt-5.6-luna";
              reviewer = "anthropic/claude-opus-5";
              scout = "azure-openai-responses/gpt-5.6-luna";
            };
            warnings = {
              anthropicExtraUsage = false;
            };
            doubleEscapeAction = "none";
          };
          models = {
            providers.anthropic = {
              baseUrl = "http://127.0.0.1:3456";
              apiKey = "x";
              compat.supportsMidConvoEffort = false;
              headers.x-meridian-agent = "pi";
            };
          };
        };

        home.file = {
          ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;
          ".pi/agent/themes/${theme.name}.json".text = builtins.toJSON theme;
          ".pi/agent/extensions/herdr-agent-state.ts" = lib.mkIf config.local.home-manager.herdr.enable {
            source = "${inputs.herdr}/src/integration/assets/pi/herdr-agent-state.ts";
          };
        };
      };
  }
