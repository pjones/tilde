# Packages compiled for aarch64.
{}@args:
let
  sources = import ../nix/sources.nix;
  overlay = import ../overlays;
  pkgs = import sources.nixpkgs;

  settings = {
    crossSystem =
      (import "${sources.nixpkgs}/lib").systems.examples.aarch64-multiplatform;
  } // args;
in
(pkgs settings).appendOverlays [ overlay ]
