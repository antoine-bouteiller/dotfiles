{
  config,
  lib,
  pkgs,
  ...
}: {
  systemd.services.bluetooth-logger.enable = false;
  systemd.services.bluetooth-link-monitor = {
    description = "Monitor Bluetooth link failures and disconnects";
    wantedBy = ["bluetooth.target"];
    before = ["bluetooth.service"];
    serviceConfig = {
      CapabilityBoundingSet = "CAP_NET_RAW";
      NoNewPrivileges = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      Restart = "always";
      RestartSec = "5s";
    };
    script = ''
      set -o pipefail
      ${lib.getExe' pkgs.coreutils "stdbuf"} -oL ${lib.getExe' config.hardware.bluetooth.package "btmon"} -P -c never -C 160 |
        ${lib.getExe pkgs.gawk} '
          BEGIN {
            commands = "(Create Connection( Cancel)?|(Accept|Reject) Connection Request|Disconnect|LE (Extended )?Create Connection( Cancel)?)"
          }
          /^[^[:space:]]/ {
            gsub(/ {2,}/, " ")
            header = $0
            sub(/^.*\[[0-9]+\]: /, "", header)
            keep = (header ~ ("^< HCI Command: " commands " \\(") ||
                    header ~ /^> HCI Event: (Connect (Request|Complete)|Disconnect Complete|Auth Complete|Encryption Change( v2)?|Hardware Error) \(/ ||
                    header ~ /^@ MGMT Event: (Device (Connected|Disconnected)|Connect Failed|Authentication Failed|Controller Error) \(/ ||
                    header ~ /^(= (New|Delete|Open|Close) Index:|Bluetooth monitor ver )/)
            # btmon prints the command or LE subevent on the next line.
            detail = ""
            if (header ~ /^> HCI Event: Command (Status|Complete) /)
              detail = commands
            if (header ~ /^> HCI Event: LE Meta Event /)
              detail = "LE (Enhanced )?Connection Complete( v2)?"
            if (keep) { print; fflush() }
            pending = $0
            next
          }
          detail != "" {
            keep = ($0 ~ ("^      " detail " \\("))
            if (keep) { print pending; print; fflush() }
            detail = ""
            next
          }
          keep && /^        ((BR\/EDR |LE |Peer )?[Aa]ddress|Handle|Status|Reason|Code|Error|Encryption): / {
            print
            fflush()
          }
        '
    '';
  };
}
