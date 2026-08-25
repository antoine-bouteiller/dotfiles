{config, ...}: let
  constants = import ../shared/constants.nix;
in {
  sops.secrets = {
    "recyclarr/sonarr_api_key" = {
      owner = constants.recyclarr.user;
      key = "sonarr_api_key";
    };
    "recyclarr/radarr_api_key" = {
      owner = constants.recyclarr.user;
      key = "radarr_api_key";
    };
  };

  users.users.recyclarr = {
    isSystemUser = true;
    group = constants.recyclarr.group;
  };
  users.groups.recyclarr = {};
  services.recyclarr = {
    enable = true;

    configuration = {
      sonarr = {
        sonarr = {
          base_url = "http://localhost:${toString config.services.sonarr.settings.server.port}";
          api_key = {
            _secret = config.sops.secrets."recyclarr/sonarr_api_key".path;
          };

          delete_old_custom_formats = true;

          quality_definition = {
            type = "series";
            preferred_ratio = "0.5";
          };

          quality_profiles = [
            {
              trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
            }
            {
              trash_id = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
            }
          ];

          custom_format_groups = {
            add = [
              {
                trash_id = "85fae4a2294965b75710ef2989c850eb"; # [Streaming Services] HD/UHD boost
                select = [
                  "218e93e5702f44a68ad9e3c6ba87d2f0" # HD Streaming Boost
                  "43b3cf48cb385cd3eac608ee6bca7f09" # UHD Streaming Boost
                ];
              }
              {
                trash_id = "59c3af66780d08332fdc64e68297098f"; # [Unwanted] Unwanted Formats
                select = [
                  "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                  "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                  "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                  "6f808933a71bd9666531610cb8c059cc" # BR-DISK (BTN)
                  "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                  "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                  "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                  # "82d40da2bc6923f41e14394075dd4b03"  # No-RlsGroup
                  # "e1a997ddb54e3ecbfe06341ad323c458"  # Obfuscated
                  # "06d66ab109d4d2eddb2794d21526d140"  # Retags
                  # "1b3994c551cbb92a2c781af061f4ab44"  # Scene
                  "23297a736ca77c0fc8e70f8edd7ee56c" # Upscaled
                ];
              }
              {
                trash_id = "d920fd959d220306888f40b6f38e1578"; # [Optional] Season Packs
              }
            ];
          };
        };
      };

      radarr = {
        radarr = {
          base_url = "http://localhost:${toString config.services.radarr.settings.server.port}";
          api_key = {
            _secret = config.sops.secrets."recyclarr/radarr_api_key".path;
          };

          delete_old_custom_formats = true;

          quality_definition = {
            type = "sqp-streaming";
            qualities = [
              {
                name = "WEBDL-1080p";
                min = 12.5;
                preferred = 25;
                max = 60;
              }
              {
                name = "WEBRip-1080p";
                min = 12.5;
                preferred = 25;
                max = 60;
              }
              {
                name = "Bluray-1080p";
                min = 25.2;
                preferred = 50.4;
                max = 80;
              }
            ];
          };

          quality_profiles = [
            {
              trash_id = "90a3370d2d30cbaf08d9c23b856a12c8"; # [SQP] SQP-1 WEB (1080p)
              min_format_score = 10;
            }
          ];

          custom_format_groups = {
            add = [
              {
                trash_id = "15b1cf0b6f1a1493856a4355907affee"; # [Unwanted] Unwanted Formats SQP
                select = [
                  "b6832f586342ef70d9c128d40c07b872" # Bad Dual Groups
                  "cc444569854e9de0b084ab2b8b1532b2" # Black and White Editions
                  "e6886871085226c3da1830830146846c" # Generated Dynamic HDR
                  "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
                ];
              }
            ];
          };
        };
      };
    };
  };

  systemd.services.recylarr.serviceConfig = {
    User = constants.recyclarr.user;
    Group = constants.recyclarr.group;
  };
}
