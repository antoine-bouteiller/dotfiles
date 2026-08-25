{
  config,
  pkgs,
  ...
}: let
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
    defaults.monitored = "-a -o on -s (S/../.././02|L/../../6/03) -m <nomailer> -M exec ${smartdWebhook}";
    notifications.mail.enable = false;
  };
}
