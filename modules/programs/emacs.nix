{ inputs, ... }:
{
  flake.homeModules.emacs =
    { ... }:
    {
      imports = [
        inputs.emacsrc.homeModules.emacsrc
      ];
    };
}
