{ moduleWithSystem, ... }:
{
  flake.nixosModules.bluetooth = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        hardware.bluetooth.enable = true;
        services.blueman.enable = true;
      };
    }
  );
}
