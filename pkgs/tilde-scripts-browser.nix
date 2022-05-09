{ stdenvNoCC
, lib
, tildeInstallScripts
, chromium
, coreutils
, wmctrl
, xdo
}:
let
  path = lib.makeBinPath [
    chromium
    coreutils
    wmctrl
    xdo
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
