{ moduleWithSystem, ... }:
{
  flake.nixosModules.networking = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        networking = {
          nat.enable = true;
          useDHCP = false;

          networkmanager = {
            enable = true;
            plugins = [ ];
          };
        };
      };
    }
  );
}
