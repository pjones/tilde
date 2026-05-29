{ moduleWithSystem, ... }:
{
  flake.nixosModules.nullmailer = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.nullmailer;
    in
    {
      options.tilde.programs.nullmailer = {
        address = lib.mkOption {
          type = lib.types.str;
          default = config.tilde.email;
          description = "Sender and recipient address";
        };

        domain = lib.mkOption {
          type = lib.types.str;
          default = config.networking.domain;
          description = "Domain for machines that don't have one set";
        };

        remotesFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to the nullmailer remotes file.

            NOTE: This file needs to be readable by
            `config.services.nullmailer.group` but should otherwise be
            private.
          '';
        };
      };
      config = {
        services.nullmailer = {
          enable = true;
          remotesFile = cfg.remotesFile;

          config = {
            adminaddr = cfg.address;
            allmailfrom = cfg.address;
            defaultdomain = cfg.domain;
            defaulthost = cfg.domain;
            pausetime = "60";
            maxpause = "14400"; # 4 hours.
            me = config.networking.hostName + "." + cfg.domain;
          };
        };
      };
    }
  );
}
