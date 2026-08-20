{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.miniflux = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.miniflux;
      clientID = cfg.sso.clientIDs.miniflux;
    in
    {
      options.tilde.programs.miniflux = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "rss.${config.networking.domain}";
          description = "The public domain name for Miniflux";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = self.lib.services.miniflux;
          description = "Port that Miniflux listens on";
        };

        sso = self.lib.kanidm.ssoOptions config ''
          Enable support for OAuth/OIDC.

          When this is enabled you must configure following items in the
          secrets file:

          ```
          OAUTH2_CLIENT_SECRET=replace_me
          ```
        '';

        secretsFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to a file that contains secrets such as the admin
            username and password.  For example:

            ```
            ADMIN_USERNAME=something
            ADMIN_PASSWORD=something
            ```
          '';
        };
      };

      config = {

        ########################################################################
        # Service Config
        services.miniflux = {
          enable = true;
          adminCredentialsFile = cfg.secretsFile;

          config = {
            LISTEN_ADDR = "127.0.0.1:${toString cfg.port}";
            HTTPS = "true";
            BASE_URL = "https://${cfg.domain}";
          }
          // lib.optionalAttrs cfg.sso.enable {
            DISABLE_LOCAL_AUTH = "true";
            OAUTH2_PROVIDER = "oidc";
            OAUTH2_CLIENT_ID = clientID;
            OAUTH2_REDIRECT_URL = "https://${cfg.domain}/oauth2/oidc/callback";
            OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://${cfg.sso.domain}/oauth2/openid/${clientID}";
            OAUTH2_USER_CREATION = 1;
          };
        };

        ########################################################################
        # Reverse Proxy:
        tilde.www.forwards = lib.singleton {
          name = cfg.domain;
          to = "http://127.0.0.1:${toString cfg.port}";
        };

        ########################################################################
        # Backup:
        scripts.backup.postgresql = {
          enable = true;
          databases = [ "miniflux" ];
        };
      };
    }
  );

  perSystem = { pkgs, ... }: {
    packages.miniflux-logo = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      name = "miniflux-logo";

      phases = [
        "installPhase"
        "fixupPhase"
      ];

      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/miniflux/logo/refs/heads/master/icon.svg";
        hash = "sha256-BASbdX8IB0GBBUm+bIXveirGo70ZiZMeduCpZIQZrZc=";
      };

      installPhase = ''
        mkdir -p "$out/share"
        cp "${finalAttrs.src}" "$out/share/logo.svg"
      '';
    });
  };
}
