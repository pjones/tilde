{ moduleWithSystem, ... }:
{
  flake.nixosModules.sudo = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        security.sudo.extraConfig = ''
          Defaults insults
        '';
      };
    }
  );
}
