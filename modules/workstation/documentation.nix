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

          # Needed for tools like Emacs to list installed man pages.
          man.cache = {
            enable = true;
            generateAtRuntime = true;
          };
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
