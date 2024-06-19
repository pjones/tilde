{ stdenvNoCC
, lib
, tildeInstallScripts
, chromium
, coreutils
}:
let
  path = lib.makeBinPath [
    chromium
    coreutils
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts-browser";
  phases = [ "installPhase" "fixupPhase" ];

  nativeBuildInputs = [
    tildeInstallScripts
  ];

  installPhase = ''
    installScripts "$out" "${../scripts/browser}" "${path}"
  '';
}
