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

  inherit ((import ../../../../../lib/palette.nix {inherit lib;})) colors;
  theme = {
    name = "pi";
    vars = colors;
    export = {
      pageBg = colors.backgroundDark;
      cardBg = colors.background;
      infoBg = colors.surface;
    };
    colors = {
      accent = "magenta";
      border = "surfaceHover";
      borderAccent = "periwinkle";
      borderMuted = "surfaceRaised";
      success = "green";
      error = "red";
      warning = "yellow";
      muted = "textMuted";
      dim = "textDim";
      text = "text";
      thinkingText = "textSecondary";
      selectedBg = "surface";
      userMessageBg = "surface";
      userMessageText = "text";
      customMessageBg = "backgroundDim";
      customMessageText = "text";
      customMessageLabel = "magenta";
      toolPendingBg = "backgroundDim";
      toolSuccessBg = "surface";
      toolErrorBg = "surface";
      toolTitle = "blue";
      toolOutput = "textSubtle";
      mdHeading = "magenta";
      mdLink = "blue";
      mdLinkUrl = "steelBlue";
      mdCode = "orange";
      mdCodeBlock = "textSecondary";
      mdCodeBlockBorder = "surfaceHover";
      mdQuote = "textMuted";
      mdQuoteBorder = "surfaceHover";
      mdHr = "surfaceHover";
      mdListBullet = "magenta";
      toolDiffAdded = "green";
      toolDiffRemoved = "red";
      toolDiffContext = "textMuted";
      syntaxComment = "textSubtle";
      syntaxKeyword = "magenta";
      syntaxFunction = "blue";
      syntaxVariable = "rose";
      syntaxString = "green";
      syntaxNumber = "orange";
      syntaxType = "yellow";
      syntaxOperator = "cyan";
      syntaxPunctuation = "textSubtle";
      thinkingOff = "surfaceRaised";
      thinkingMinimal = "surfaceHover";
      thinkingLow = "blue";
      thinkingMedium = "steelBlue";
      thinkingHigh = "magenta";
      thinkingXhigh = "red";
      bashMode = "orange";
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
            lastChangelogVersion = customPkgs.pi.version;
            theme = theme.name;
            defaultProvider =
              if agents.claude-code.enable
              then "anthropic"
              else "azure-openai-responses";
            defaultModel =
              if agents.claude-code.enable
              then "claude-opus-5-5"
              else "gpt-6-sol";
            enabledModels =
              [
                "azure-openai-responses/gpt-6-astra"
                "azure-openai-responses/gpt-6-sol"
              ]
              ++ (
                if agents.claude-code.enable
                then ["anthropic/claude-opus-5-5"]
                else ["azure-openai-responses/claude-opus-5-5"]
              );
            herdr = {
              allowedModels =
                [
                  "azure-openai-responses/gpt-6-sol"
                ]
                ++ (
                  if agents.claude-code.enable
                  then ["anthropic/claude-opus-5-5"]
                  else ["azure-openai-responses/claude-opus-5-5"]
                );
            };
            packages = [
              "npm:@ff-labs/pi-fff"
              "git:github.com/antoine-bouteiller/pi-extensions"
              "git:github.com/antoine-bouteiller/plan-viewer"
            ];
            npmCommand = [
              "bun"
            ];
            defaultThinkingLevel = "medium";
            compaction.enabled = false;
            tuiMode = "fullscreen";
            warnings = {
              anthropicExtraUsage = false;
            };
            doubleEscapeAction = "none";
          };
          models = {
            providers.anthropic = lib.mkIf agents.claude-code.enable {
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
