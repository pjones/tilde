{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.bitlbee = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.bitlbee;
    in
    {
      options.tilde.programs.bitlbee = {
        password = lib.mkOption {
          type = lib.types.str;
          description = ''
            The output of:

            `bitlbee -x hash <password>`
          '';
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = "bitlbee.${config.networking.domain}";
          description = "The hostname Bitlbee will announce itself as";
        };
      };

      config = {
        services.bitlbee = {
          enable = true;
          interface = config.tilde.privateInterface;
          hostName = cfg.hostname;
          portNumber = self.lib.services.bitlbee;

          extraSettings = ''
            AuthPassword = md5:${cfg.password}
            OperPassword = md5:${cfg.password}
          '';

          libpurple_plugins = with pkgs.pidginPackages; [
            purple-discord # Ug.
            purple-slack # Also Ug.
          ];
        };
      };
    }
  );

}
