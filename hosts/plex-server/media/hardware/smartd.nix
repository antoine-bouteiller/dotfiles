{
  config,
  lib,
  pkgs,
  ...
}: let
  constants = import ../shared/constants.nix;
  smartdWebhook = pkgs.writeShellScript "smartd-webhook" ''
        ALERT_TEXT="SMART Disk Warning
    Device: $SMARTD_DEVICE
    Event: $SMARTD_FAILTYPE
    Details: $SMARTD_MESSAGE"

        PAYLOAD=$(${pkgs.jq}/bin/jq -n \
          --arg msg "$ALERT_TEXT" \
          '{ "text": $msg }')

        ${pkgs.curl}/bin/curl -sS --fail-with-body -X POST \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          "http://localhost:${toString config.services.autoscan.port}/send_message" \
          || echo "smartd webhook failed" >&2
  '';
in {
  services.smartd = {
    enable = true;
    autodetect = true;
    # Short test every Sunday 02:00, long test on the 1st of each month 03:00.
    defaults.monitored = "-a -o on -s (S/../../7/02|L/../01/./03) -m <nomailer> -M exec ${smartdWebhook}";
    # Don't wake the backup disk on every 30 min poll; force a check (and any
    # missed scheduled test) after 48 skips (~1 day).
    devices = [
      {
        device = constants.disks.backup;
        options = "-n standby,48,q";
      }
    ];
    notifications.mail.enable = false;
  };

  environment.systemPackages = [pkgs.hdparm pkgs.smartmontools];

  # Spin the backup disk down after 20 min idle, e.g. once a scan finishes.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", SYMLINK=="${lib.removePrefix "/dev/" constants.disks.backup}", RUN+="${pkgs.hdparm}/bin/hdparm -S 240 /dev/%k"
  '';
}
