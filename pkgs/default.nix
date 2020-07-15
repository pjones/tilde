{}@args:
let
  sources = import ../nix/sources.nix;
  overlay = import ../overlays;
  pkgs = import sources.nixpkgs;
in
(pkgs args).appendOverlays [ overlay ]
