{ self, moduleWithSystem, ... }:
{
  flake.nixosModules.laptop = moduleWithSystem (
    { pkgs, ... }:
    { config, lib, ... }:
    {
      config = {
        home-manager.users.${config.tilde.username} = {
          imports = [ self.homeModules.laptop ];
        };

        environment.systemPackages = with pkgs; [
          acpi # Show battery status and other ACPI information
          powertop # Analyze power consumption on Intel-based laptops
        ];

        # Use the local time zone:
        services.geoclue2.enable = true;
        services.localtimed.enable = true;
        location.provider = "geoclue2";
        time.timeZone = lib.mkForce null;

        # Sleeping (see sleep.conf.d(5)):
        #
        # Only set these if you want to force hibernation earlier:
        #  HibernateDelaySec=2h
        #  SuspendEstimationSec=10m
        systemd.sleep.extraConfig = ''
          SuspendState=mem
        '';

        services.logind.settings.Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchDocked = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
        };

        # Useful services:
        hardware.acpilight.enable = true;
        services.thermald.enable = pkgs.stdenv.isx86_64;
        services.upower.enable = true;
      };
    }
  );

  flake.homeModules.laptop = moduleWithSystem (
    { ... }:
    { ... }:
    {
      # Placeholder.
    }
  );
}
