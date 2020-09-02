{ stdenvNoCC
, lib
, tildeInstallScripts
, coreutils
, findutils
, gnugrep
}:
let
  path = lib.makeBinPath [
    coreutils
    findutils
    gnugrep
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts";
  phases = [ "installPhase" "fixupPhase" ];

  nativeBuildInputs = [
    tildeInstallScripts
  ];

  installPhase = ''
    installScripts "$out" "${../scripts/misc}" "${path}"
  '';
}
