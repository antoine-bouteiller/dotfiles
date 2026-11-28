_: {
  home.stateVersion = "26.05";
  local.home-manager.agents.claude-code.enable = true;

  programs.umbriel.settings.output."eDP-1".scale = 2.0;

  local.home-manager.desktop.extraNiriConfig = ''
    output "eDP-1" {
        // 4K panel: everything is unreadable at 1:1.
        scale 2
    }
  '';
}
