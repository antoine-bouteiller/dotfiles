_: {
  home.stateVersion = "26.05";

  local.home-manager.desktop.extraNiriConfig = ''
    output "eDP-1" {
        // 4K panel: everything is unreadable at 1:1.
        scale 2
    }
  '';
}
