{ self, moduleWithSystem, ... }:
{
  flake.homeModules.syncthing = moduleWithSystem (
    { ... }:
    { config, lib, ... }:
    let
      cfg = config.tilde.programs.syncthing;
    in
    {
      options.tilde.programs.syncthing = {
        gui.ip = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "IP address to bind the GUI to";
        };

        gui.port = lib.mkOption {
          type = lib.types.port;
          default = self.lib.services.syncthing;
          description = "The port the GUI will listen on";
        };
      };

      config = {
        services.syncthing = {
          enable = true;
          extraOptions = [ "--gui-address=${cfg.gui.ip}:${toString cfg.gui.port}" ];
        };
      };
    }
  );
}
