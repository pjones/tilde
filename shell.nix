{ pkgs ? import ./pkgs { }
}:

pkgs.mkShell {
  name = "account-shell";
  buildInputs = with pkgs;
    [
      nixops
    ];
}
