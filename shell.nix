{ pkgs ? import ./pkgs { }
}:
pkgs.mkShell {
  name = "account-shell";

  # Override the location of the home-manager config file:
  HOME_MANAGER_CONFIG = toString ./home.nix;

  buildInputs = with pkgs;
    [
      home-manager
      nixops
    ];
}
