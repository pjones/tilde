{ stdenv
, fetchzip
, lib
}:

stdenv.mkDerivation {
  pname = "virtue";
  version = "3.2.1";

  src = fetchzip {
    url = "http://www.scootergraphics.com/virtue/virtue.zip";
    hash = "sha256-964FGecUkcRAeJLmm97tpBd+1l9cNxL0dHTUxAqjLJw=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp -a virtue.ttf $out/share/fonts/truetype
  '';

  meta = with lib; {
    description = "Improvement of Apple Computer's \"Charcoal\" font appearing in Mac OS 8.";
    homepage = "http://www.scootergraphics.com/virtue/";
    license = licenses.free;
    platforms = platforms.all;
    maintainers = with maintainers; [ pjones ];
  };
}
