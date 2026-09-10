{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [../../modules/home];

  # Shared modules use the checkout path normally supplied by NixOS/nix-darwin.
  # apply-remote builds from GitHub without a checkout, so point at the flake's store copy.
  local.home-manager.sourcePath = "${inputs.self}";

  local.home-manager = {
    shell-tools.enable = true;
    zsh.localConfigFile = "${config.home.homeDirectory}/.local/share/dotfiles/zvm";
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
    packages = [pkgs.bat];
    # mise-managed JDKs read this; cap heap so a runaway JVM cannot OOM the VM.
    sessionVariables.JAVA_TOOL_OPTIONS = "-XX:MaxRAMPercentage=70";
  };

  # Standalone HM cannot change the login shell; hand interactive bash off to zsh.
  programs.bash = {
    enable = true;
    initExtra = "exec ${lib.getExe pkgs.zsh} -l";
  };

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;
}
