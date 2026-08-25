{config, ...}: let
  constants = import ../shared/constants.nix;
in {
  sops.secrets = {
    "authelia/jwt_secret" = {
      owner = constants.authelia.user;
    };
    "authelia/storage_encryption_key" = {
      owner = constants.authelia.user;
    };
    "authelia/session_secret" = {
      owner = constants.authelia.user;
    };
    "authelia/resend_api_key" = {
      owner = constants.authelia.user;
    };
  };

  services.authelia.instances.main = {
    enable = true;

    secrets = {
      storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
      sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
      jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
    };

    environmentVariables = {
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."authelia/resend_api_key".path;
    };

    settings = {
      theme = "dark";

      # Only Caddy talks to Authelia. Keep the forward-auth endpoint off the
      # network so clients cannot bypass Caddy's forwarded-header boundary.
      server.address = "tcp://127.0.0.1:9091/";

      server.endpoints.authz.forward-auth = {
        implementation = "ForwardAuth";
        # Default strategies are [HeaderAuthorization(Basic), CookieSession], and a
        # failing Authorization header short-circuits with 401 + WWW-Authenticate
        # instead of falling through to the cookie. CoolerControl's API authenticates
        # with `Authorization: Basic`, so Authelia would check CCAdmin against its own
        # users and trap the browser in a native auth popup. Cookies only.
        authn_strategies = [{name = "CookieSession";}];
      };

      identity_validation.reset_password = {
        jwt_lifespan = "5 minutes";
        jwt_algorithm = "HS256";
      };

      authentication_backend.file = {
        path = "${constants.authelia.dataDir}/users.yml";
        password.algorithm = "argon2";
      };

      password_policy.zxcvbn = {
        enabled = true;
        min_score = 3;
      };

      access_control = {
        default_policy = "deny";

        rules = [
          {
            domain = "*.${constants.network.domain}";
            policy = "one_factor";
          }
        ];
      };

      session.cookies = [
        {
          name = "authelia_session";
          domain = constants.network.domain;
          authelia_url = "https://auth.${constants.network.domain}";
        }
      ];

      regulation = {
        max_retries = 3;
        find_time = "2 minutes";
        ban_time = "5 minutes";
      };

      log.level = "info";

      storage.local.path = "${constants.authelia.dataDir}/db.sqlite3";

      notifier = {
        disable_startup_check = false;
        smtp = {
          address = "submissions://smtp.resend.com:465";
          username = "resend";
          sender = "authelia@${constants.network.domain}";
        };
      };
    };
  };

  local.media.authelia = {
    host = "auth";
    port = constants.authelia.port;
    # The authentication portal cannot itself require forward authentication.
    auth = false;
  };
}
