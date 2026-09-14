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
  hooksDir = ./hooks;
in
  mkModule args "local.home-manager.agents.claude-code" {
    description = "claude-code, with its config and ~/.claude/skills";

    # The native HM module owns the package, MCP integration, settings, and context.
    config = _:
      lib.mkIf agents.enable {
        programs.claude-code = {
          enable = true;
          package = customPkgs.claude-code;
          enableMcpIntegration = true;
          context = ./CLAUDE.md;
          settings = {
            permissions = {
              deny = [
                "DesignSync"
                "NotebookEdit"
                "SendMessage"
                "PushNotification"
                "RemoteTrigger"
                "ScheduleWakeup"
                "CronCreate"
                "CronDelete"
                "CronList"
                "EnterWorktree"
                "ExitWorktree"
                "ShareOnboardingGuide"
              ];
              defaultMode = "auto";
              additionalDirectories = [
                "~/.claude"
              ];
            };
            model = "fable[1m]";
            disableClaudeAiConnectors = true;
            disableBundledSkills = true;
            hooks = {
              PostToolUse = [
                {
                  matcher = "Write|Edit|MultiEdit";
                  hooks = [
                    {
                      type = "command";
                      command = "comment-checker";
                    }
                  ];
                }
              ];
              PreToolUse = [
                {
                  matcher = "Bash";
                  hooks = [
                    {
                      type = "command";
                      command = "rtk hook claude";
                    }
                    {
                      type = "command";
                      command = "${hooksDir}/validate-no-ai-trailer.sh";
                      timeout = 5;
                    }
                    {
                      type = "command";
                      command = "${hooksDir}/block-dangerous-git.sh";
                    }
                  ];
                }
              ];
              SessionStart = lib.mkIf config.local.home-manager.herdr.enable [
                {
                  matcher = "*";
                  hooks = [
                    {
                      type = "command";
                      command = "${lib.getExe pkgs.bash} ${inputs.herdr}/src/integration/assets/claude/herdr-agent-state.sh session";
                      timeout = 10;
                    }
                  ];
                }
              ];
              Stop = [
                {
                  matcher = "*";
                  hooks = [
                    {
                      type = "command";
                      command = "${hooksDir}/stop_caffeinate.sh";
                    }
                  ];
                }
              ];
              UserPromptSubmit = [
                {
                  matcher = "*";
                  hooks = [
                    {
                      type = "command";
                      command = "${hooksDir}/start_caffeinate.sh";
                    }
                    {
                      type = "command";
                      command = "${hooksDir}/user-prompt-check.sh";
                      timeout = 5;
                    }
                  ];
                }
              ];
            };
            disableRemoteControl = true;
            disableWorkflows = true;
            disableArtifact = true;
            statusLine = {
              type = "command";
              command = "bunx -y ccstatusline@latest";
              padding = 0;
              refreshInterval = 10;
            };
            feedbackSurveyRate = 0;
            effortLevel = "medium";
            tui = "fullscreen";
            skipDangerousModePermissionPrompt = true;
            skipWorkflowUsageWarning = true;
            agentPushNotifEnabled = false;
            skipAutoPermissionPrompt = true;
          };
        };

        xdg.configFile."ccstatusline/settings.json".source = ./ccstatusline.json;
      };
  }
