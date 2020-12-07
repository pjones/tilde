{ stdenvNoCC
, lib
, tildeInstallScripts
, chromium-launcher
, coreutils
, wmctrl
, xdo
}:
let
  path = lib.makeBinPath [
    chromium-launcher
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
