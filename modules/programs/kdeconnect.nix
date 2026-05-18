{ moduleWithSystem, ... }:
{
  flake.homeModules.kdeconnect = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        services.kdeconnect = {
          enable = true;
          indicator = true;
        };
      };
    }
  );
}
