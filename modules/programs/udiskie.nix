{ moduleWithSystem, ... }:
{
  flake.nixosModules.udiskie = moduleWithSystem (
    { ... }:
    {
      config = {
        services.udisks2.enable = true;
      };
    }
  );

  flake.homeModules.udiskie = moduleWithSystem (
    { ... }:
    {
      config = {
        # Tray icon for disks:
        services.udiskie = {
          enable = true;
          automount = false;
        };
      };
    }
  );
}
