{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.znc = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.znc;

      userOptions = { name, ... }: {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "User name";
          };

          admin = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "This user has admin rights";
          };

          nick = lib.mkOption {
            type = lib.types.str;
            description = "IRC nick";
          };

          config = lib.mkOption {
            type = with lib.types; attrsOf anything;
            description = "Extra ZNC configuration";
            default = { };
          };

          password = {
            method = lib.mkOption {
              type = lib.types.str;
              default = "sha256";
              description = "Password method";
            };

            hash = lib.mkOption {
              type = lib.types.str;
              description = ''
                Password hash created by:

                `znc --makepass`
              '';
            };

            salt = lib.mkOption {
              type = with lib.types; nullOr str;
              default = null;
              description = "Salt when using the SHA-256 method";
            };
          };
        };
      };

      toUser =
        name: user:
        lib.recursiveUpdate {
          Admin = user.admin;
          Nick = user.nick;

          Pass.password.Method = user.password.method;
          Pass.password.Hash = user.password.hash;
          Pass.password.Salt = user.password.salt;

          LoadModule = [
            "autoreply"
            "push"
          ];

          Network.libera = {
            Server = "irc.libera.chat +6697";

            LoadModule = [
              "keepnick"
              "simple_away"
              "nickserv"
            ];

            Chan = {
              "#nixos" = { };
              "#emacs" = { };
            };
          };
        } user.config;
    in
    {
      options.tilde.programs.znc = {
        users = lib.mkOption {
          type = with lib.types; attrsOf (submodule userOptions);
          default = { };
          description = "Attribute set of users";
        };
      };

      config = {
        services.znc = {
          enable = true;
          mutable = false;
          useLegacyConfig = false;
          modulePackages = with pkgs.zncModules; [ push ];

          config = {
            LoadModule = [ "adminlog" ];

            # Need to overwrite the default config that includes a
            # listener called `l`:
            Listener.l = {
              Host = config.tilde.privateInterface;
              Port = self.lib.services.znc;
              SSL = false;
              AllowIRC = true;
              AllowWeb = false;
            };

            User = builtins.mapAttrs toUser cfg.users;
          };
        };

        systemd.services.znc = self.lib.nixos.waitForTilde config;
      };
    }
  );
}
