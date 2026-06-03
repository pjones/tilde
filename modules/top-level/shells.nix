{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        NIX_PATH = "nixpkgs=${pkgs.path}";

        nativeBuildInputs = [
          inputs.home-manager.packages.${system}.home-manager
          pkgs.fastfetch
          pkgs.nixpkgs-fmt
          pkgs.nixd
        ];
      };
    };
}
