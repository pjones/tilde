{ stdenvNoCC
, lib
, inputs
}:

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = builtins.substring 0 7 inputs.firefox-csshacks.rev;

  src = inputs.firefox-csshacks;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out
    cp -a chrome content $out/
  '';
}
