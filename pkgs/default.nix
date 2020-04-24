{ # Which Haskell compiler to use:
  ghc ? "default",

  # Where all the packages are defined:
  sources ? import ../nix/sources.nix
}:

let
  # A nixpkgs overlay:
  overlay = self: super: {
    pjones = import ./overlay.nix { inherit sources; };
  };

  # Load nixpkgs from the sources.nix file:
  pkgs = import sources.nixpkgs {
    overlays = [ overlay ];
  };

in pkgs
