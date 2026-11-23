{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.luciole.homeModules.default];

  config = lib.mkMerge [
    {
      programs.luciole.package = lib.mkIf (!pkgs.stdenv.hostPlatform.isLinux) null;
    }
    (lib.mkIf config.local.home-manager.desktop.enable {
      programs.luciole = {
        enable = true;
        settings.browser.terminal_command = "foot";
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications."inode/directory" = ["dev.noctalia.luciole.desktop"];
      };
    })
  ];
}
