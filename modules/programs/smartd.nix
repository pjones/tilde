{ moduleWithSystem, ... }:
{
  flake.nixosModules.smartd = moduleWithSystem (
    { pkgs, ... }:
    { config, ... }:
    let
      cfg = config.tilde;
    in
    {
      config = {
        environment.systemPackages = with pkgs; [
          smartmontools
        ];

        # Monitor the SMART status on compatible drives:
        # See: smartd.conf(5)
        services.smartd = {
          enable = true;
          autodetect = true;
          defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";

          notifications = {
            mail = {
              enable = cfg.email != null;
              sender = cfg.email;
              recipient = cfg.email;
            };
          };
        };
      };
    }
  );
}
