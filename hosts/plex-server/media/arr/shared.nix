# Shared Servarr integration. Inputs are the service name and whether the
# service writes to the media library; Prowlarr passes false.
{
  config,
  lib,
  name,
  managesMedia,
}: let
  constants = import ../shared/constants.nix;
in
  lib.mkMerge [
    {
      services.${name} =
        {
          enable = true;
          dataDir = constants.${name}.dataDir;
          settings = {
            server.bindAddress = "127.0.0.1";
            auth.method = "external";
            postgres = {
              host = "/run/pgbouncer";
              port = 5432;
              user = name;
              mainDb = name;
              logDb = "${name}-log";
            };
          };
        }
        // lib.optionalAttrs managesMedia {
          group = constants.libraryOwner.group;
        };

      local.media.${name} = {
        port = config.services.${name}.settings.server.port;
        auth = true;
      };

      systemd.services.${name} =
        {
          after = ["pgbouncer.service"];
          requires = ["pgbouncer.service"];
        }
        // lib.optionalAttrs managesMedia {
          serviceConfig.UMask = lib.mkForce "002";
        };
    }
    (lib.optionalAttrs managesMedia {
      systemd.tmpfiles.rules = [
        "d '${constants.paths.mediaDir}/torrents/${name}' 0775 ${constants.libraryOwner.user} ${constants.libraryOwner.group} - -"
      ];
      users.users.${name}.extraGroups = [constants.libraryOwner.group];
    })
  ]
