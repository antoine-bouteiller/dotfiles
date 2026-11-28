{
  lib,
  stdenv,
  writeShellApplication,
  writeShellScript,
  zenity,
}: let
  inherit (stdenv.hostPlatform) isDarwin;
  askpass = writeShellScript "sudo-askpass" (
    if isDarwin
    then ''
      exec /usr/bin/osascript - "$1" <<'APPLESCRIPT'
      on run argv
        return text returned of (display dialog (item 1 of argv) with title "sudo authentication" default answer "" buttons {"Cancel", "Authenticate"} default button "Authenticate" cancel button "Cancel" with hidden answer)
      end run
      APPLESCRIPT
    ''
    else ''
      exec ${lib.getExe zenity} --entry --hide-text --title="sudo authentication" --text="$1"
    ''
  );
in
  writeShellApplication {
    name = "sudo";
    text = ''
      sudo=${
        if isDarwin
        then "/usr/bin/sudo"
        else "/run/wrappers/bin/sudo"
      }
      if [[ -n ''${SSH_CONNECTION:-} ]]; then
        exec "$sudo" "$@"
      fi
      ${
        if isDarwin
        then ''
          if [[ $(/bin/launchctl managername 2>/dev/null) != Aqua ]]; then
            exec "$sudo" "$@"
          fi
        ''
        else ''
          socket=''${WAYLAND_DISPLAY:-}
          if [[ -n $socket && $socket != /* ]]; then
            socket=''${XDG_RUNTIME_DIR:-}/$socket
          fi
          if [[ ! -S $socket ]]; then
            exec "$sudo" "$@"
          fi
        ''
      }
      export SUDO_ASKPASS="''${SUDO_ASKPASS:-${askpass}}"
      # Sudo rejects -A with -S. Scan only sudo's options, not the command's arguments.
      skip=false
      for arg do
        if $skip; then
          skip=false
          continue
        fi
        case $arg in
          --) break ;;
          --auth-type|--close-from|--login-class|--chdir|--group|--host|--prompt|--chroot|--role|--command-timeout|--type|--other-user|--user)
            skip=true ;;
          --background|--edit|--set-home|--login|--list|--preserve-env|--preserve-groups|--reset-timestamp|--no-update|--shell|--validate|--*=*) ;;
          --*) exec "$sudo" "$@" ;;
          -?*)
            if [[ $arg =~ ^-[^aCcDghpRrTtUu]*[ASn] ]]; then
              exec "$sudo" "$@"
            fi
            if [[ $arg =~ ^-[^aCcDghpRrTtUu]*[aCcDghpRrTtUu]$ ]]; then
              skip=true
            fi ;;
          [!/=]*=*) ;;
          *) break ;;
        esac
      done
      exec "$sudo" -A "$@"
    '';
  }
