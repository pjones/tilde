{ stdenvNoCC
, fetchurl
, imagemagick
}:

stdenvNoCC.mkDerivation rec {
  name = "pjones-avatar";
  phases = [ "installPhase" "fixupPhase" ];

  src = fetchurl {
    url = "https://avatars2.githubusercontent.com/u/3737";
    sha256 = "06h7rnchya4nqq7igaa9j2n9mm2xcmgzlisl418ify8hh8xv3q5r";
  };

  installPhase = ''
    mkdir -p "$out/share/sddm/faces"
    ${imagemagick}/bin/convert ${src} "png:$out/share/sddm/faces/pjones.face.icon"
  '';
}
