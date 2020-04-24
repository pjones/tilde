{ config, pkgs, lib, ... }:

{
  imports = [
    ./nixos
  ];

  nixpkgs.overlays = [
    (import ./pkgs/overlay.nix {})
  ];
}
