{host, ...}: {
  services.hardware.openrgb = {
    enable = true;
    startupProfile = "Purple.orp";
  };
  systemd.tmpfiles.rules = [
    "L+ /var/lib/OpenRGB/Purple.orp - - - - ${./Purple.orp}"
  ];
  systemd.services.openrgb.restartTriggers = [./Purple.orp];

  # The GUI lists local profiles, not the SDK server's profiles.
  home-manager.users.${host.user}.xdg.configFile = {
    "OpenRGB/OpenRGB.json".source = ./OpenRGB.json;
    "OpenRGB/Purple.orp".source = ./Purple.orp;
    "OpenRGB/Stopped.orp".source = ./Stopped.orp;
  };
}
