{ pkgs, self }:

let
  fakeClientKey = "ahaes2oche0MeiPae6Ahpacoag5theez8Oca2out";

  fakePasswordFile = toString (
    pkgs.runCommand "client-key" { } ''
      echo "${fakeClientKey}" >"$out"
    ''
  );

  fakeClientIDs = {
    immich = "ohveph6eejeigiengak2";
    vaultwarden = "ca4ea8aujaawie1tahro";
    miniflux = "thaeti9bivahtieghi5a";
  };

in
pkgs.testers.nixosTest {
  name = "tilde-kanidm";

  nodes.acme = { modulesPath, ... }: {
    imports = [
      (modulesPath + "/../tests/common/acme/server")
    ];
  };

  nodes.kanidm = { modulesPath, ... }: {
    imports = [
      (modulesPath + "/../tests/common/acme/client")
      self.nixosModules.test
      self.nixosModules.kanidm
      self.nixosModules.miniflux
      self.nixosModules.vaultwarden
    ];

    networking = {
      domain = "test";

      hosts."127.0.0.1" = [
        "vaultwarden.test"
        "kanidm.test"
        "miniflux.test"
      ];
    };

    tilde.www.defaultHost = "vaultwarden.test";

    tilde.programs.vaultwarden = {
      domain = "vaultwarden.test";
      organizationName = "Tilde";
      emailFromAddress = "example@test";
      sso.enable = true;
      sso.domain = "kanidm.test";
      sso.clientIDs = fakeClientIDs;

      environmentFile = toString (
        pkgs.runCommand "env-vars" { } ''
          echo SSO_CLIENT_SECRET="${fakeClientKey}" >>"$out"
          echo SMTP_HOST=smtp.test >>"$out"
        ''
      );
    };

    tilde.programs.miniflux = {
      domain = "miniflux.test";
      sso.enable = true;
      sso.domain = "kanidm.test";
      sso.clientIDs = fakeClientIDs;

      secretsFile = toString (
        pkgs.runCommand "miniflux-secrets-file" { } ''
          echo "ADMIN_USERNAME=something" >>"$out"
          echo "ADMIN_PASSWORD=something" >>"$out"
          echo "OAUTH2_CLIENT_SECRET=${fakeClientKey}" >>"$out"
        ''
      );
    };

    tilde.programs.kanidm = {
      domain = "kanidm.test";
      clientIDs = fakeClientIDs;

      config.provision = {
        # For tests only:
        acceptInvalidCerts = true;

        adminPasswordFile = fakePasswordFile;
        idmAdminPasswordFile = fakePasswordFile;

        persons = {
          tilde = {
            displayName = "Tilde User";
            mailAddresses = [ "tilde@example.test" ];
            groups = [
              "immich_admins"
              "immich_users"
              "miniflux_users"
              "vaultwarden_users"
            ];
          };
        };
      };

      services.immich = {
        enable = true;
        domain = "immich.test";
        basicSecretFile = fakePasswordFile;
      };

      services.miniflux = {
        enable = true;
        domain = "miniflux.test";
        basicSecretFile = fakePasswordFile;
      };

      services.vaultwarden = {
        enable = true;
        domain = "vaultwarden.test";
        basicSecretFile = fakePasswordFile;
      };
    };
  };

  nodes.immich = { nodes, modulesPath, ... }: {
    imports = [
      (modulesPath + "/../tests/common/acme/client")
      self.nixosModules.test
      self.nixosModules.immich
    ];

    virtualisation = {
      cores = 2;
      memorySize = 2048;
      diskSize = 4096;
    };

    networking = {
      domain = "test";

      hosts.${nodes.kanidm.networking.primaryIPAddress} = [
        "kanidm.test"
      ];
    };

    tilde.www.defaultHost = "immich.test";

    tilde.programs.immich = {
      domain = "immich.test";
      sso.enable = true;
      sso.domain = "kanidm.test";
      sso.clientIDs = fakeClientIDs;
      sso.clientSecretFile = fakePasswordFile;
    };
  };

  testScript = ''
    acme.wait_for_open_port(443)
    kanidm.wait_for_unit("miniflux.service")
    kanidm.wait_for_unit("vaultwarden.service")
    kanidm.wait_for_unit("kanidm.service")
    immich.wait_for_unit("immich-server.service")

    kanidm.succeed(r"""
      curl \
        --insecure \
        --silent \
        --show-error \
        --fail \
        --json '{"email": "foo@bar.com"}' \
        --output /dev/null \
        --write-out '%{http_code}' \
        https://vaultwarden.test/api/organizations/domain/sso/verified |
        grep '200'
    """)

    # Miniflux makes it easy to test Kandim:
    kanidm.succeed(r"""
      curl \
        --insecure \
        --silent \
        --show-error \
        --fail \
        --location \
        --output /dev/null \
        https://miniflux.test/oauth2/oidc/redirect
    """)

    # Immich tests:
    immich.wait_for_open_port(${toString self.lib.services.immich})

    immich.succeed(r"""
      curl \
        --insecure \
        --silent \
        --show-error \
        --fail \
        --output /dev/null \
        http://localhost:${toString self.lib.services.immich}/
    """)

    # Can't really test the OIDC redirect because it's done in JS.
    immich.succeed(r"""
      curl \
        --insecure \
        --silent \
        --show-error \
        --fail \
        --output /dev/null \
        --write-out '%{http_code}' \
        https://immich.test/auth/login |
        grep -E '200'
    """)

    # Metrics:
    immich.wait_until_succeeds("curl -sSf http://localhost:${toString self.lib.services.prometheus-immich-api}/metrics")
    immich.wait_until_succeeds("curl -sSf http://localhost:${toString self.lib.services.prometheus-immich-microservices}/metrics")
  '';
}
