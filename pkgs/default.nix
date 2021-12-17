{ pkgs ? import <nixpkgs> { } }:
pkgs.appendOverlays [ (import ./overlay.nix) ]
