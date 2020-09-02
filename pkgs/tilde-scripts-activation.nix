{ stdenvNoCC
, lib
, tildeInstallScripts
, coreutils
, findutils
, gnugrep
, gnused
, man-db
}:
let
  path = lib.makeBinPath [
    coreutils
    findutils
    gnugrep
    gnused
    man-db
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts-activation";
  phases = [ "installPhase" "fixupPhase" ];

  nativeBuildInputs = [
    tildeInstallScripts
  ];

  installPhase = ''
    installScripts "$out" "${../scripts/activation}" "${path}"
  '';
}
