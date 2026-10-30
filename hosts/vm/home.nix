{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Long-lived remote sessions survive SSH connections. Keep their inherited path
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
    workstation.enable = true;
    # Headless: reached over SSH, no local terminal emulator.
    terminal.enable = false;
    agents.claude-code.enable = true;
  };

  # The age key exists only while apply-remote activates, which writes it here and
  # removes it after; login runs skip, and secrets stay on disk across reboots.
  sops = {
    age.keyFile = "${config.xdg.stateHome}/sops-nix/age-key.txt";
    defaultSecretsMountPoint = "${config.xdg.stateHome}/sops-nix/secrets.d";
  };
  systemd.user.services.sops-nix.Unit.ConditionPathExists = config.sops.age.keyFile;

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
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.lightpanda
      sonarqube-cli
      glab
      alsa-lib # libasound.so.2
      at-spi2-core # libatk-bridge-2.0.so.0
    ];
    sessionVariables = {
      # mise-managed JDKs read this; low enough that several concurrent JVMs fit in RAM.
      JAVA_TOOL_OPTIONS = "-XX:MaxRAMPercentage=25";
      AGENT_BROWSER_ENGINE = "lightpanda";
    };
  };

  # Standalone HM cannot change the login shell; hand interactive bash off to zsh.
  programs.bash = {
    enable = true;
    # Must run before the interactive guard: `ssh host command` sessions are non-interactive.
    bashrcExtra = sshAgentSocket;
    initExtra = "exec ${lib.getExe pkgs.zsh} -l";
  };
  programs.zsh.envExtra = sshAgentSocket;

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
}
