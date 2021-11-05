{ stdenvNoCC
, lib
}:

let
  sources = import ../nix/sources.nix;
in

stdenvNoCC.mkDerivation {
  pname = "firefox-csshacks";
  version = builtins.substring 0 7 sources.firefox-csshacks.rev;

  src = sources.firefox-csshacks;
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out
    cp -a chrome content $out/
  '';
}
