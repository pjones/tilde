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
          man.cache.enable = false; # Slow and broken.
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
          man.generateCaches = false; # Slow and broken
          info.enable = true;
        };
      };
    }
  );
}
