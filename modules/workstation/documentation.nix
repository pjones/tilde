{ moduleWithSystem, ... }:
{
  flake.nixosModules.documentation = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        documentation = {
          enable = true;
          man.enable = true;
          info.enable = true;
          doc.enable = true;
          dev.enable = true;
          man.cache.enable = true;
        };
      };
    }
  );

  flake.homeModules.documentation = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        programs = {
          man.enable = true;
          man.generateCaches = true;
          info.enable = true;
        };
      };
    }
  );
}
