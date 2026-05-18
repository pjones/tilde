{ moduleWithSystem, ... }:
{
  flake.nixosModules.avahi = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        services.avahi = {
          enable = true;
          nssmdns4 = true;
        };
      };
    }
  );
}
