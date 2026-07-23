{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        NIX_PATH = "nixpkgs=${pkgs.path}";

        nativeBuildInputs = [
          inputs.home-manager.packages.${system}.home-manager
          pkgs.fastfetch # Screenshots
          pkgs.gitMinimal # For nix-on-droid
          pkgs.python3 # For editing Python files
          pkgs.ruff # For editing Python files
        ];
      };
    };
}
