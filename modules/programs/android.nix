{ moduleWithSystem, ... }:
{
  flake.nixosModules.android = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        programs.adb.enable = true;
        tilde.extraGroups = [ "adbusers" ];
      };
    }
  );
}
