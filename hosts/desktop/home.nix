_: {
  home.stateVersion = "26.05";

  local.home-manager.desktop.extraNiriConfig = ''
    output "DP-1" {
        mode "1920x1080@60.000"
        scale 1
        position x=0 y=180
    }
    output "DP-3" {
        mode "2560x1440@143.972"
        scale 1
        position x=1920 y=0
    }
  '';
}
