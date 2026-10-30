{
  mkModule,
  config,
  host,
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

      # The SSH host key is a recipient of secrets/agent.yaml; users have no age key here.
      sops = {
        age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
        secrets.pi-agent = {
          sopsFile = inputs.self + "/secrets/agent.yaml";
          key = "";
          format = "yaml";
          owner = host.user;
        };
      };

      home-manager.sharedModules = [
        {
          local.home-manager.workstation.enable = lib.mkDefault true;
          local.home-manager.agents.pi.agentSecretFile = config.sops.secrets.pi-agent.path;
        }
      ];

      environment.systemPackages = with pkgs; [
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
