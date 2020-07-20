{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  name = "account-scripts";
  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 555 ${./image-cache} $out/bin/image-cache
    install -m 555 ${./lock-screen} $out/bin/lock-screen
    install -m 555 ${./random-file} $out/bin/random-file
  '';
}
