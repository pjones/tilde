{ sources ? import ./nix/sources.nix
, pkgs ? import ./pkgs { }
}:
let
  nix_path = {
    nixpkgs = sources.nixpkgs.url;
    home-manager = sources.home-manager.url;
    nix-on-droid = sources.nix-on-droid.url;
  };
in
pkgs.mkShell {
  name = "account-shell";

  buildInputs =
    with pkgs;
    with pkgs.lib;
    [ git ]
    ++ optional (pkgs.system == "x86_64-linux") nixops
    ++ optional (pkgs.system == "aarch64-linux") nix-on-droid;

  # Export a good NIX_PATH for tools that run in this shell.
  NIX_PATH = with pkgs.lib;
    concatStringsSep ":"
      (mapAttrsToList (name: value: "${name}=${value}") nix_path);
}
