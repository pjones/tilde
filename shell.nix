{ sources ? import ./nix/sources.nix
, pkgs ? import ./pkgs { }
}:
let
  inherit (pkgs) lib;

  nix_path = {
    nixpkgs = sources.nixpkgs.url;
    home-manager = sources.home-manager.url;
    nix-on-droid = sources.nix-on-droid.url;
  };
in
pkgs.mkShell {
  name = "tilde-shell";

  buildInputs =
    [ pkgs.git ]
    ++ lib.optional (pkgs.system == "x86_64-linux") pkgs.nixops
    ++ lib.optional (pkgs.system == "aarch64-linux") pkgs.nix-on-droid;

  # Export a good NIX_PATH for tools that run in this shell.
  NIX_PATH = lib.concatStringsSep ":"
    (lib.mapAttrsToList (name: value: "${name}=${value}") nix_path);
}
