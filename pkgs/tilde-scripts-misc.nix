{ stdenvNoCC
, lib
, tildeInstallScripts
, coreutils
, findutils
, gnugrep
, imv
}:
let
  path = lib.makeBinPath [
    coreutils
    findutils
    gnugrep
    imv
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
