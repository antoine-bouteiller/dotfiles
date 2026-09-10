_: {
  home.stateVersion = "26.05";

  # ponytail: copied from the Dell panel; replace with this machine's outputs once its displays are known.
  local.home-manager.desktop.extraNiriConfig = ''
    output "eDP-1" {
        // 4K panel: everything is unreadable at 1:1.
        scale 2
    }
  '';
}
