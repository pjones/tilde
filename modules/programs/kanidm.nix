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

          domain = lib.mkOption {
            type = lib.types.str;
            default = config.services.vaultwarden.domain;
            description = "The name of the host running VaultWarden";
          };

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
              originUrl = "https://${cfg.services.vaultwarden.domain}/identity/connect/oidc-signin";
              originLanding = "https://${cfg.services.vaultwarden.domain}";
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

        # Kanidm won't start without these:
        systemd.services.kanidm.unitConfig.ConditionPathExists = [
          "${home}/fullchain.pem"
          "${home}/key.pem"
        ];

        tilde.www.forwards = lib.singleton {
          name = cfg.domain;
          to = "https://127.0.0.1:${toString cfg.port}";
        };

        security.acme.certs.${config.tilde.www.defaultHost} = {
          postRun = ''
            has_file=0

            if [ -e "${home}/key.pem" ]; then
              has_file=1
            fi

            install --mode=0700 --owner=kanidm --group=kanidm -d "${home}"

            for file in {key,fullchain}.pem; do
              install --mode=0400 --owner=kanidm --group=kanidm "$file" "${home}"
            done

            if [ "$has_file" -eq 0 ]; then
              # Kanidm is not started
              systemctl --no-block start kanidm.service
            else
              systemctl --no-block try-reload-or-restart kanidm.service
            fi
          '';
        };

        scripts.backup.snapshot.kanidm = {
          directory = home;
          destination = "${config.scripts.backup.directory}/kanidm";
        };
      };
    }
  );
}
