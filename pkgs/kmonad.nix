{ haskellPackages
, haskell
}:

let
  inherit (haskell.lib) justStaticExecutables;
  inherit (haskellPackages) callCabal2nix;

  sources = import ../nix/sources.nix;

  drv =
    justStaticExecutables
      (callCabal2nix "kmonad" sources.kmonad { });
in
drv
