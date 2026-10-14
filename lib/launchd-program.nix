# Builds launchd ProgramArguments that write stdout and stderr to
# `<logDir>/<name>.{log,err}` with a timestamp on each line, which launchd's
# StandardOutPath and StandardErrorPath cannot do.
#
#   ProgramArguments = launchdProgram {
#     name = "nh-clean";
#     logDir = "/Library/Logs";
#     command = [(lib.getExe pkgs.nh) "clean" "all"];
#   };
#
# `logDir` is expanded by the shell, so "$HOME/Library/Logs" works for user agents.
{
  lib,
  pkgs,
}: {
  name,
  logDir,
  command,
}: let
  ts = "${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S'";
in [
  # Named after the service so Login Items shows it instead of "sh"; the final
  # exec keeps the command as the job's main process and exit status.
  (lib.getExe (pkgs.writeShellScriptBin name ''
    mkdir -p "${logDir}"
    exec > >(${ts} >> "${logDir}/${name}.log") 2> >(${ts} >> "${logDir}/${name}.err")
    exec ${lib.escapeShellArgs command}
  ''))
]
