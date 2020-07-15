{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  name = "account-scripts";
  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 555 ${./random-file} $out/bin/random-file
  '';
}
