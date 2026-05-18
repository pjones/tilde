{ inputs, ... }:
{
  flake.homeModules.emacs =
    { ... }:
    {
      imports = [
        inputs.emacsrc.homeManagerModules.default
      ];

      config = {
        programs.pjones.emacsrc.enable = true;
      };
    };
}
