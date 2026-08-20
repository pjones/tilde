{ pkgs, self }:

let
  fakeClientKey = "ahaes2oche0MeiPae6Ahpacoag5theez8Oca2out";

  fakePasswordFile = toString (
    pkgs.runCommand "client-key" { } ''
      echo "${fakeClientKey}" >"$out"
    ''
  );

  fakeClientIDs = {
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

  nodes.machine = { modulesPath, ... }: {
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
            groups = [ "vaultwarden_users" ];
          };
        };
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

  testScript = ''
    acme.wait_for_open_port(443)
    machine.wait_for_unit("miniflux.service")
    machine.wait_for_unit("vaultwarden.service")
    machine.wait_for_unit("kanidm.service")

    machine.succeed(r"""
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
    machine.succeed(r"""
      curl \
        --insecure \
        --silent \
        --show-error \
        --fail \
        --location \
        --output /dev/null \
        https://miniflux.test/oauth2/oidc/redirect
    """)
  '';
}
