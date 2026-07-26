{config, ...}: let
  constants = import ./constants.nix;
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
              trash_id = "72dae194fc92bf828f32cde7744e51a1"; # [Anime] Remux-1080p
            }
          ];

          custom_format_groups = {
            add = [
              {
                trash_id = "f4a0410a1df109a66d6e47dcadcce014"; # [Optional] Miscellaneous
                select = [
                  "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                  "ef4963043b0987f8485bc9106f16db38" # DV (Disk)
                  "1bd69272e23c5e6c5b1d6c8a36fce95e" # HFR
                  "7ba05c6e0e14e793538174c679126996" # MULTi
                  "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                  "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                  "06d66ab109d4d2eddb2794d21526d140" # Retags
                  "1b3994c551cbb92a2c781af061f4ab44" # Scene
                  "7470a681e6205243983c4410ee4c920f" # VC-1
                  "90501962793d580d011511155c97e4e5" # VP9
                  "cddfb4e32db826151d97352b8e37c648" # x264
                  "c9eafd50846d299b862ca9bb6ea91950" # x265
                  "041d90b435ebd773271cea047a457a6a" # x266
                ];
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
