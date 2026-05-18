{ moduleWithSystem, ... }:
{
  flake.homeModules.direnv = moduleWithSystem (
    { ... }:
    { ... }:
    {
      config = {
        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };
    }
  );
}
