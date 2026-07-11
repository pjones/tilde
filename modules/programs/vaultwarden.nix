{ moduleWithSystem, ... }:
{
  flake.nixosModules.vaultwarden = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.vaultwarden;
    in
    {
      options.tilde.programs.vaultwarden = {
        debug = lib.mkEnableOption "Debugging output";

        domain = lib.mkOption {
          type = lib.types.str;
          description = "The external domain name";
        };

        port = lib.mkOption {
          type = lib.types.ints.positive;
          default = 8222;
          description = "The port VaultWarden listens on";
        };

        environmentFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to file containing secret environment variables";
        };

        organizationName = lib.mkOption {
          type = lib.types.str;
          description = "The publicly visible organization name";
        };

        emailFromAddress = lib.mkOption {
          type = lib.types.str;
          description = "The email address to send invitations from";
        };

        config = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Additional config to forwarded to services.vaultwarden.config";
        };

        sso = {
          enable = lib.mkEnableOption ''
            Basic SSO configuration

            You must provide the following values in the `environmentFile`:

            - SSO_AUTHORITY
            - SSO_CLIENT_ID
            - SSO_CLIENT_SECRET
          '';
        };
      };

      config = {
        services.vaultwarden = {
          inherit (cfg) domain environmentFile;

          enable = true;
          dbBackend = "postgresql";
          configurePostgres = true;

          config = {
            SIGNUPS_ALLOWED = false;
            INVITATIONS_ALLOWED = true;
            INVITATION_ORG_NAME = cfg.organizationName;

            ENABLE_WEBSOCKET = true;
            ROCKET_ADDRESS = "127.0.0.1";
            ROCKET_PORT = cfg.port;

            SMTP_FROM = cfg.emailFromAddress;
            SMTP_FROM_NAME = "Bitwarden Bot";
          }
          // lib.optionalAttrs cfg.sso.enable {
            SSO_ENABLED = true;
            SSO_ONLY = true;
            SSO_SIGNUPS_MATCH_EMAIL = true;
            SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION = false;
            SSO_PKCE = true;
            SSO_AUTH_ONLY_NOT_SESSION = true;
          }
          // lib.optionalAttrs cfg.debug {
            ROCKET_LOG = "debug";
            LOG_LEVEL = "debug";
            EXTENDED_LOGGING = true;
          }
          // cfg.config;
        };

        tilde.www.forwards = lib.singleton {
          name = cfg.domain;
          to = "http://127.0.0.1:${toString cfg.port}";
        };

        scripts.backup.postgresql = {
          enable = true;
          databases = [ "vaultwarden" ];
        };
      };
    }
  );

}
