{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.adguardhome = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.adguardhome;

      adminOption = { ... }: {
        options = {
          username = lib.mkOption {
            type = lib.types.str;
            description = "User name for this admin user";
          };

          password = lib.mkOption {
            type = lib.types.str;
            description = ''
              BCrypt-encrypted password.

              Generate with `mkpasswd -m bcrypt -R 10`.

              **NOTE:** This password will be in the Nix store.
            '';
          };
        };
      };
    in
    {
      options.tilde.programs.adguardhome = {
        admins = lib.mkOption {
          type = with lib.types; listOf (submodule adminOption);
          default = [ ];
          description = "List of administrators";
        };

        nameservers = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = "List of upstream DNS servers to use";
        };

        rewrites = lib.mkOption {
          type = with lib.types; attrsOf str;
          default = { };
          example = lib.literalExpression ''
            {
              foo = "127.0.0.1";
              noevil = "8.8.8.8";
            }
          '';
          description = ''
            A set of domain names and IP addresses for AdGuard to
            respond with.
          '';
        };
      };

      config = {
        services.adguardhome = {
          enable = true;
          allowDHCP = false;
          port = self.lib.services.adguardhome;
          settings = {
            dns.bind_hosts = [ "0.0.0.0" ];
            dns.upstream_dns = cfg.nameservers;

            users = map (admin: {
              name = admin.username;
              password = admin.password;
            }) cfg.admins;

            filtering.rewrites = lib.mapAttrsToList (domain: answer: {
              inherit domain answer;
              enabled = true;
            }) cfg.rewrites;
          };
        };
      };
    }
  );
}
