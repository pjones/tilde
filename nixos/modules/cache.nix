# Binary caches:
{ config, pkgs, lib, ... }:

{
  nix = {
    binaryCaches = [
      "https://cache.nixos.org/"
      "https://static-haskell-nix.cachix.org"
    ];

    binaryCachePublicKeys = [
      "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
    ];
  };
}
