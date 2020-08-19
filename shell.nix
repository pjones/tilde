{ sources ? import ./nix/sources.nix
, pkgs ? import ./pkgs { }
}:
let
  nix_path = {
    nixpkgs = sources.nixpkgs.url;
    home-manager = sources.home-manager.url;
  };
in
pkgs.mkShell {
  name = "account-shell";

  buildInputs = with pkgs; [
    nixops
  ];

  # Export a good NIX_PATH for tools that run in this shell.
  NIX_PATH = with pkgs.lib;
    concatStringsSep ":"
      (mapAttrsToList (name: value: "${name}=${value}") nix_path);
}
