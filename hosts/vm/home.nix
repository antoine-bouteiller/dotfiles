{
  host,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # HerdR's daemon and panes survive SSH connections. Keep their inherited path
  # stable, without letting short-lived SSH probes displace a working connection.
  # A socket can outlive its usable agent; require keys and bound health checks.
  sshAgentSocket = ''
    if [[ -n "''${SSH_CONNECTION:-}" ]]; then
      if [[ -n "''${SSH_AUTH_SOCK:-}" &&
            "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" &&
            -S "$SSH_AUTH_SOCK" ]] &&
         ! SSH_AUTH_SOCK="$HOME/.ssh/agent.sock" ${pkgs.coreutils}/bin/timeout 2s ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1 &&
         ${pkgs.coreutils}/bin/timeout 2s ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1; then
        mkdir -p -m 700 -- "$HOME/.ssh"
        ln -sfn -- "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
      fi
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
  '';
in {
  imports = [../../modules/home];

  # Shared modules use the checkout path normally supplied by NixOS/nix-darwin.
  # apply-remote builds from copied sources without a checkout, so use the flake's store copy.
  local.home-manager.sourcePath = "${inputs.self}";

  local.home-manager = {
    shell-tools.enable = true;
    herdr.enable = true;
    agents = {
      enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
  };

  programs.mcp.servers = {
    linear = {
      type = "http";
      url = "https://mcp.linear.app/mcp";
      headers.Authorization = "Bearer \${LINEAR_TOKEN}";
    };
    figma = {
      type = "http";
      url = "https://mcp.figma.com/mcp";
      oauth = {
        clientName = "Claude Code";
        scope = "mcp:connect";
      };
    };
  };

  home = {
    username = host.user;
    homeDirectory = "/home/${host.user}";
    stateVersion = "26.05";
    # Ansible owns the login profile; keep Home Manager from managing it.
    file.".bash_profile".enable = false;
    packages = with pkgs; [
      bat
      yamllint
      agent-browser
      sonarqube-cli
      glab
    ];
    # mise-managed JDKs read this; cap heap so a runaway JVM cannot OOM the VM.
    sessionVariables.JAVA_TOOL_OPTIONS = "-XX:MaxRAMPercentage=70";
  };

  # Standalone HM cannot change the login shell; hand interactive bash off to zsh.
  programs.bash = {
    enable = true;
    # Must run before the interactive guard: HerdR starts via `ssh host command`.
    bashrcExtra = sshAgentSocket;
    initExtra = "exec ${lib.getExe pkgs.zsh} -l";
  };
  programs.zsh.envExtra = sshAgentSocket;

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
}
