{config, ...}: let
  constants = import ../shared/constants.nix;
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

      # Delete the .torrent file once it has been handed to the session.
      Core.AutoDeleteAddedTorrentFile = "IfAdded";

      BitTorrent = {
        ExcludedFileNamesEnabled = true;

        Session = {
          DefaultSavePath = downloadDir;
          Preallocation = true;
          # Stop seeding as soon as a torrent completes.
          GlobalMaxRatio = 0;
          # The proxy only carries TCP, so uTP/UDP would leak outside the tunnel.
          BTProtocol = "TCP";
          # Auto torrent management on by default: categories decide the paths.
          DisableAutoTMMByDefault = false;
          ExcludedFileNames = "*.rar, *.r[0-9]*, *.exe, *.zip";
        };
      };

      Network = {
        # No UPnP/NAT-PMP mapping of the torrenting port.
        PortForwardingEnabled = false;
        # Resolve hostnames locally rather than through the proxy.
        Proxy.HostnameLookupEnabled = false;
      };

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
