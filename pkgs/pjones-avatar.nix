{
  stdenvNoCC,
  fetchurl,
  imagemagick,
}:

stdenvNoCC.mkDerivation rec {
  name = "pjones-avatar";
  phases = [
    "installPhase"
    "fixupPhase"
  ];

  src = fetchurl {
    url = "https://avatars2.githubusercontent.com/u/3737";
    hash = "sha256-4N+lAlOo39Kz0jQRTZsDFhMarA+d/QkhNB+pA4hlekY=";
  };

  installPhase = ''
    mkdir -p "$out/share/faces" "$out/share/sddm/faces"
    cp "${src}" "$out/share/faces/pjones.jpg"
    ${imagemagick}/bin/convert \
      -define colorspace:auto-grayscale=false \
      "${src}" "png:$out/share/sddm/faces/pjones.face.icon"
  '';
}
