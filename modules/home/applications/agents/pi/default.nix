{
  mkModule,
  mkUserService,
  config,
  lib,
  pkgs,
  inputs,
  ...
} @ args: let
  agents = config.local.home-manager.agents;
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
  claudeProvider =
    if agents.claude-code.enable
    then "anthropic"
    else "azure";

  secretFiles = ["${config.local.home-manager.sourcePath}/secrets/agent.yaml"] ++ agents.pi.extraSecretFiles;

  # pi runs with the agent API keys decrypted into its own process only.
  # Decrypting then exec'ing, rather than nesting `sops exec-env`, keeps pi as the terminal's
  # foreground process, which Rex uses to identify the pane. Earlier files take precedence.
  piWrapped = pkgs.writeShellScriptBin "pi" ''
    set -o pipefail
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''export ${name}=''${${name}:-${lib.escapeShellArg value}}'') agents.pi.env)}
    export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-${config.home.homeDirectory}/.config/sops/age/keys.txt}"
    for f in ${lib.escapeShellArgs (lib.reverseList secretFiles)}; do
      exports=$(${lib.getExe pkgs.sops} decrypt --output-type json "$f" | ${lib.getExe pkgs.jq} -r 'to_entries[] | "export \(.key)=\(.value | @sh)"') || exit
      eval "$exports"
    done
    exec ${lib.getExe customPkgs.pi} "$@"
  '';

  # Extension updates need no API keys, so skip the sops wrapper.
  piUpdateExtensions = pkgs.writeShellApplication {
    name = "pi-update-extensions";
    runtimeInputs = [pkgs.bun pkgs.git];
    text = "exec ${lib.getExe customPkgs.pi} update --extensions";
  };

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
      lib.mkIf agents.enable (lib.mkMerge [
        {
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
                else "azure";
              defaultModel =
                if agents.claude-code.enable
                then "claude-opus-5-5"
                else "gpt-6.1-sol";
              enabledModels =
                [
                  "azure/gpt-6.1-sol"
                ]
                ++ (
                  if agents.claude-code.enable
                  then ["anthropic/claude-opus-5-5" "anthropic/claude-sonnet-5-5"]
                  else ["azure/claude-opus-5-5" "azure/claude-sonnet-5-5"]
                );
              herdr = {
                allowedModels =
                  [
                    "azure/gpt-6.1-sol"
                  ]
                  ++ (
                    if agents.claude-code.enable
                    then ["anthropic/claude-opus-5-5" "anthropic/claude-sonnet-5-5"]
                    else ["azure/claude-opus-5-5" "azure/claude-sonnet-5-5"]
                  );
                modelNotes = let
                  claude =
                    if agents.claude-code.enable
                    then "anthropic"
                    else "azure";
                in {
                  "azure/gpt-6.1-sol" = "default for implementation, debugging, design/architecture, scouting, and research; required for all reviews of Claude-produced work (including Sonnet)";
                  "${claude}/claude-opus-5-5" = "deep review of GPT-produced work; independent second opinions on difficult design/architecture or debugging";
                  "${claude}/claude-sonnet-5-5" = "quick, well-scoped implementation tasks; lightweight review of GPT-produced work";
                };
              };
              packages = [
                "npm:@ff-labs/pi-fff"
                "git:github.com/antoine-bouteiller/pi-extensions"
                "git:github.com/antoine-bouteiller/skills"
              ];
              npmCommand = [
                "bun"
              ];
              defaultTools = ["+codemode"];
              defaultThinkingLevel = "high";
              compaction.enabled = true;
              tuiMode = "fullscreen";
              warnings = {
                anthropicExtraUsage = false;
              };
              doubleEscapeAction = "none";
            };
            models = {
              providers.azure.modelOverrides."gpt-6.1-sol".contextWindow = 1050000;
              providers.anthropic = lib.mkIf agents.claude-code.enable {
                baseUrl = "http://127.0.0.1:3456";
                apiKey = "x";
                compat.supportsMidConvoEffort = false;
                headers.x-meridian-agent = "pi";
              };
            };
          };

          # Bare gcm (staged) and gcam (tracked) let pi commit with the conventional-commit
          # skill, which is explicit-invocation only. The skill asks before splitting, so -p
          # mode must delegate that decision. mkAfter places this after the git.nix aliases.
          programs.zsh.initContent = lib.mkAfter ''
            unalias gcm gcam 2>/dev/null
            gcm() {
              emulate -L zsh
              if (( $# )); then
                git commit -m "$@"
                return
              fi
              git diff --cached --quiet && { print -u2 "nothing staged to commit"; return 1; }
              ${lib.getExe piWrapped} -p --no-session --no-mcp --offline --tools bash,read --thinking low \
                --model ${claudeProvider}/claude-sonnet-5-5 \
                "/skill:conventional-commit Commit the staged changes. Splitting is delegated: split into several commits when the skill's rules call for it, without asking."
            }
            gcam() {
              emulate -L zsh
              if (( $# )); then
                git commit -a -m "$@"
                return
              fi
              git add -u && gcm
            }
          '';

          home.file = {
            ".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;
            ".pi/agent/themes/${theme.name}.json".text = builtins.toJSON theme;
            ".pi/agent/mcp.json" = lib.mkIf (config.programs.mcp.enable && config.programs.mcp.servers != {}) {
              inherit (config.xdg.configFile."mcp/mcp.json") source;
            };
            ".pi/agent/extensions/herdr-agent-state.ts" = lib.mkIf config.local.home-manager.herdr.enable {
              source = "${inputs.herdr}/src/integration/assets/pi/herdr-agent-state.ts";
            };
          };
        }
        (mkUserService args "pi-update-extensions" {
          description = "Update pi extensions";
          command = lib.getExe piUpdateExtensions;
          interval = 3600;
        })
      ]);
  }
