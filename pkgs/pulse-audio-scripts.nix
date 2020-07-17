{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  name = "pulse-audio-scripts";
  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 0555 ${../support/workstation/paswitch.sh} $out/bin/paswitch
  '';
}
