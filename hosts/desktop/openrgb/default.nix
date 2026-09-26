{
  config,
  host,
  lib,
  pkgs,
  ...
}: {
  services.hardware.openrgb = {
    enable = true;
    startupProfile = "Purple.json";
  };
  systemd.tmpfiles.rules = [
    "r /var/lib/OpenRGB/Purple.orp"
    "L+ /var/lib/OpenRGB/profiles/Purple.json - - - - ${./Purple.json}"
  ];
  systemd.services.openrgb.restartTriggers = [./Purple.json];

  # The receiver stays plugged in while the mouse sleeps; HID++ reports its
  # actual connection via the mouse's battery device.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="power_supply", ATTR{model_name}=="Heat Gaming Mouse G900", TAG+="systemd", ENV{SYSTEMD_READY}="$attr{online}", ENV{SYSTEMD_WANTS}+="openrgb-mouse-online.service"
  '';
  systemd.services.openrgb-mouse-online = {
    description = "Detect G900 after it connects to its wireless receiver";
    after = ["openrgb.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! ${lib.getExe config.services.hardware.openrgb.package} --nodetect --client 127.0.0.1:6742 --list-devices | ${pkgs.gnugrep}/bin/grep 'Heat Gaming Mouse G900' > /dev/null; then
        ${pkgs.systemd}/bin/systemctl --no-block try-restart openrgb.service
      fi
    '';
  };

  # The GUI lists local profiles, not the SDK server's profiles.
  home-manager.users.${host.user}.xdg.configFile = {
    "OpenRGB/OpenRGB.json".source = ./OpenRGB.json;
    "OpenRGB/profiles/Purple.json".source = ./Purple.json;
    "OpenRGB/Stopped.orp".source = ./Stopped.orp;
  };
}
