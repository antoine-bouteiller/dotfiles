{
  mkModule,
  pkgs,
  lib,
  inputs,
  ...
} @ args: let
  customPkgs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system};
in
  mkModule args "local.nixos.workstation" {
    description = "A Linux machine used for development and desktop applications";

    config = _: {
      local.nixos.desktop.enable = lib.mkDefault true;

      home-manager.sharedModules = [
        {
          local.home-manager.workstation.enable = lib.mkDefault true;
        }
      ];

      environment.systemPackages = with pkgs; [
        # Node.js development tools
        nodejs_24
        bun
        # customPkgs.vite-plus

        customPkgs.nearby-file-share
        customPkgs.helium

        # Plex's only DisplayManager backend is X11DisplayManager, which XOpenDisplay()s
        # $DISPLAY regardless of the Qt platform plugin; with no Xwayland it fails and
        # playback segfaults. xwayland-satellite plus DISPLAY :12 from the niri config is
        # enough, so no wrapper. Only the rename is left: the desktop entry basename must
        # equal the app_id (tv.plex.Plex) or the shell can't pair the window with an icon.
        (symlinkJoin {
          name = "plex-desktop-app-id";
          paths = [plex-desktop];
          postBuild = ''
            mv $out/share/applications/plex-desktop.desktop \
              $out/share/applications/tv.plex.Plex.desktop
          '';
        })
        telegram-desktop
        bitwarden-desktop
      ];
    };
  }
