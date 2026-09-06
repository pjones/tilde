{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.immich = moduleWithSystem (
    { pkgs-unstable, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.immich;
      clientID = cfg.sso.clientIDs.immich;
    in
    {
      options.tilde.programs.immich = {
        domain = lib.mkOption {
          type = lib.types.str;
          description = "The domain name that Immich is running on";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = self.lib.services.immich;
          description = "The port number Immich should listen on";
        };

        sso = self.lib.kanidm.ssoOptions config "Basic SSO configuration" // {
          clientSecretFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to a file containing the client secret";
          };
        };
      };

      config = {
        services.immich = {
          enable = true;

          # Immich 2.x has a major security vulnerability.
          #
          # FIXME: Remove after NixOS 26.11
          package = pkgs-unstable.immich;

          host = "0.0.0.0";
          port = cfg.port;
          database.enable = true;
          database.createDB = true;

          environment = {
            IMMICH_TELEMETRY_INCLUDE = "all";
            IMMICH_API_METRICS_PORT = toString self.lib.services.prometheus-immich-api;
            IMMICH_MICROSERVICES_METRICS_PORT = toString self.lib.services.prometheus-immich-microservices;
          };

          settings = {
            server.externalDomain = "https://${cfg.domain}";
          }
          // lib.optionalAttrs cfg.sso.enable {
            oauth = {
              enabled = true;
              autoLaunch = true;
              autoRegister = true;
              clientId = clientID;
              clientSecret._secret = cfg.sso.clientSecretFile;
              issuerUrl = "https://${cfg.sso.domain}/oauth2/openid/${clientID}";
              tokenEndpointAuthMethod = "client_secret_post";
              signingAlgorithm = "ES256";
            };
          };
        };

        services.immich.machine-learning.environment = {
          IMMICH_PORT = toString self.lib.services.immich-ml;
        };

        # Reverse proxy with TLS:
        tilde.www.forwards = lib.singleton {
          name = cfg.domain;
          to = "http://127.0.0.1:${toString cfg.port}";
        };

        # Backup:
        scripts.backup.setfacl.directories = [ "/var/lib/immich" ];
      };
    }
  );

  perSystem = { pkgs, ... }: {
    packages.immich-logo = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      name = "immich-logo";

      phases = [
        "installPhase"
        "fixupPhase"
      ];

      src = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/immich-app/immich/main/design/immich-logo-stacked-light.svg";
        hash = "sha256-FViTfYGrlruuvW00vEPiGzskZLNVamtGvfIR7fyAE7g=";
      };

      installPhase = ''
        mkdir -p "$out/share"
        cp "${finalAttrs.src}" "$out/share/logo.svg"
      '';
    });
  };
}
