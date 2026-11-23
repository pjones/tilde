{ moduleWithSystem, ... }:
{
  flake.nixosModules.polkit = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        security.polkit = {
          enable = true;

          adminIdentities = [
            "unix-group:wheel"
          ];
        };
      };
    }
  );

  flake.homeModules.polkit = moduleWithSystem (
    { ... }:
    { ... }:
    {
      services.polkit-gnome.enable = true;
    }
  );

}
