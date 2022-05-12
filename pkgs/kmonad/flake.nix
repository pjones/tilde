{
  description = "Alternate flake for KMonad";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    kmonad.url = "github:kmonad/kmonad";
    kmonad.flake = false;
  };

  outputs = { self, nixpkgs, kmonad, ... }:
    let
      # List of supported systems:
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgsFor.${system};
            haskell = pkgs.haskellPackages;
            hlib = pkgs.haskell.lib;
          in
          {
            # Full Haskell package with shared/static libraries:
            lib = hlib.addBuildDepends
              (haskell.callCabal2nix "inhibit-screensaver" kmonad { })
              [ pkgs.git ];

            # Just the inhibit-screensaver executable:
            bin = hlib.justStaticExecutables self.packages.${system}.lib;
          });

      defaultPackage = forAllSystems (system:
        self.packages.${system}.bin);

      overlay = final: prev: {
        kmonad = self.packages.${prev.system}.bin;
      };
    };
}
