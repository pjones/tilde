{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.kanidm = moduleWithSystem (
    { pkgs, system, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.kanidm;
      home = "/var/lib/kanidm";
    in
    {
      options.tilde.programs.kanidm = {
        domain = lib.mkOption {
          type = lib.types.str;
          description = "External domain name";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = self.lib.services.kanidm;
          description = "Port that Kanidm listens on";
        };

        services.vaultwarden = {
          enable = lib.mkEnableOption "Configure Kanidm for VaultWarden";

          basicSecretFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to a file containing the client secret";
          };
        };

        config = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = ''
            Additional config to forwarded to the services.kanidm
            NixOS option.

            Provisioning is enabled by default so details must be
            provided in this attribute set.  Otherwise disable
            provisioning.
          '';
        };
      };

      config = {
        environment.systemPackages =
          lib.optional cfg.services.vaultwarden.enable
            self.packages.${system}.vaultwarden-logo;

        services.kanidm = lib.recursiveUpdate {
          package = pkgs.kanidmWithSecretProvisioning_1_10;

          provision = {
            enable = true;
            instanceUrl = "https://${cfg.domain}";

            groups = lib.optionalAttrs cfg.services.vaultwarden.enable {
              vaultwarden_users = { };
            };

            systems.oauth2.vaultwarden = lib.mkIf cfg.services.vaultwarden.enable {
              displayName = "VaultWarden Password Manager";
              originUrl = "https://${config.tilde.programs.vaultwarden.domain}/identity/connect/oidc-signin";
              originLanding = "https://${config.tilde.programs.vaultwarden.domain}";
              imageFile = "${self.packages.${system}.vaultwarden-logo}/share/logo.svg";
              basicSecretFile = cfg.services.vaultwarden.basicSecretFile;

              scopeMaps.vaultwarden_users = [
                "openid"
                "profile"
                "email"
              ];
            };
          };

          client = {
            enable = true;
            settings.uri = "https://${cfg.domain}";
          };

          server = {
            enable = true;
            settings = {
              domain = cfg.domain;
              origin = "https://${cfg.domain}";
              bindaddress = "127.0.0.1:${toString cfg.port}";
              tls_chain = "${home}/fullchain.pem";
              tls_key = "${home}/key.pem";
            };
          };
        } cfg.config;

        tilde.www.forwards = lib.singleton {
          name = cfg.domain;
          to = "https://127.0.0.1:${toString cfg.port}";
        };

        security.acme.certs.${cfg.domain} = {
          postRun = ''
            for file in {key,fullchain}.pem; do
              install --mode=0400 --owner=kanidm --group=kanidm "$file" "${home}"
            done
          '';

          reloadServices = [ "kanidm.service" ];
        };

        scripts.backup.snapshot.kanidm = {
          directory = home;
          destination = "${config.scripts.backup.directory}/kanidm";
        };
      };
    }
  );
}
