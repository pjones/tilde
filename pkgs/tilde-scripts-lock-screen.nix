{ stdenvNoCC
, lib
, tildeInstallScripts
, tilde-scripts-misc
, coreutils
, findutils
, gnugrep
, i3lock
, imagemagick
, inotifyTools
, player-mpris-tail
, procps
, systemd
, xrandr
, xset
}:
let
  path = lib.makeBinPath [
    tilde-scripts-misc
    coreutils
    findutils
    gnugrep
    i3lock
    imagemagick
    inotifyTools
    player-mpris-tail
    procps
    systemd
    xrandr
    xset
  ];
in
stdenvNoCC.mkDerivation {
  name = "tilde-scripts-lock-screen";
  phases = [ "installPhase" "fixupPhase" ];

  nativeBuildInputs = [
    tildeInstallScripts
  ];

  installPhase = ''
    installScripts "$out" "${../scripts/lock-screen}" "${path}"
  '';
}
