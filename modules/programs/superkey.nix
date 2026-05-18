# Temporary module until I integrate superkey into tilde.
{ inputs, ... }:
{
  flake.nixosModules.superkey =
    { ... }:
    {
      imports = [
        inputs.superkey.nixosModules.default
      ];

      config = {
        superkey.enable = true;
      };
    };

  flake.homeModules.superkey =
    { ... }:
    {
      imports = [
        inputs.superkey.homeManagerModules.default
      ];
    };
}
