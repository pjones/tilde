{
  stdenvNoCC,
  src,
}:

stdenvNoCC.mkDerivation {
  inherit src;

  pname = "firefox-csshacks";
  version = builtins.substring 0 7 src.rev;

  phases = [
    "unpackPhase"
    "installPhase"
    "fixupPhase"
  ];

  installPhase = ''
    mkdir -p $out
    cp -a chrome content $out/
  '';
}
