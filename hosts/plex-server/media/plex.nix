{...}: let
  constants = import ./constants.nix;
  inherit (import ./lib.nix) mkCaddyVirtualHost;
in {
  services.plex = {
    enable = true;
    dataDir = constants.plex.dataDir;
  };

  services.caddy.virtualHosts = mkCaddyVirtualHost {
    url = "plex.${constants.network.domain}";
    port = constants.plex.port;
    extraProxyConfig = ''
      header_up Host {host}
      header_up X-Real-IP {remote_host}
      header_up X-Forwarded-For {remote_host}
      header_up X-Forwarded-Proto {scheme}'';
  };

  systemd.tmpfiles.rules = [
    "d '${constants.paths.mediaDir}/library'        0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/library/movies' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/library/tv'     0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
    "d '${constants.paths.mediaDir}/transcode'      0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
  ];

  users.users.plex.extraGroups = [constants.libraryOwner.group];
}
