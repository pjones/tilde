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
}
