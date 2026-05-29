{ moduleWithSystem, ... }:
{
  flake.nixosModules.nix = moduleWithSystem (
    { pkgs, ... }:
    { ... }:
    {
      config = {
        nix = {
          nixPath = [ "nixpkgs=${pkgs.path}" ];

          settings.trusted-users = [ "@wheel" ];

          optimise = {
            automatic = true;
            persistent = true;
          };

          extraOptions = ''
            experimental-features = nix-command flakes
            keep-outputs = true
            keep-derivations = true
          '';
        };
      };
    }
  );
}
