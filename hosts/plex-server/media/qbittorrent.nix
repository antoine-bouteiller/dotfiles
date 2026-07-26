{config, ...}: let
  constants = import ./constants.nix;
  downloadDir = "${constants.paths.mediaDir}/torrents";
in {
  services.qbittorrent = {
    enable = true;
    user = constants.qbittorrent.user;
    group = constants.qbittorrent.group;
    openFirewall = false;
    torrentingPort = 51413;

    # The module reinstalls qBittorrent.conf from this attrset on every start,
    # so anything tweaked in the WebUI has to land here to survive a restart.
    serverConfig = {
      LegalNotice.Accepted = true;

      BitTorrent.Session = {
        DefaultSavePath = downloadDir;
        TempPathEnabled = false;
        Preallocation = true;
        # Stop seeding as soon as a torrent completes.
        GlobalMaxRatio = 0;
      };

      # No UPnP/NAT-PMP mapping of the torrenting port.
      Network.PortForwardingEnabled = false;

      Preferences.WebUI = {
        Address = "127.0.0.1";
        # Only qui, the *arr apps and the homepage widget touch this API, all
        # from localhost. qui carries the login for everything from outside.
        LocalHostAuth = false;
      };
    };
  };

  # Downloads have to stay group-writable for plex/sonarr/radarr.
  systemd.services.qbittorrent.serviceConfig.UMask = "002";

  sops.secrets."qui/session_secret" = {};

  services.qui = {
    enable = true;
    secretFile = config.sops.secrets."qui/session_secret".path;
  };

  systemd.tmpfiles.rules = [
    "d '${downloadDir}'             0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  local.media.qui = {
    port = config.services.qui.settings.port;
    auth = true;
  };
}
