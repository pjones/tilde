{ moduleWithSystem, ... }:
{
  flake.nixosModules.android = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        tilde.extraGroups = [ "adbusers" ];
      };
    }
  );
}
