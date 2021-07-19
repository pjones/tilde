{ lib
, stdenvNoCC
, fetchurl
}:

stdenvNoCC.mkDerivation rec {
  pname = "bibata-cursors";
  version = "1.1.2";

  src = fetchurl {
    url = "https://github.com/ful1e5/Bibata_Cursor/releases/download/v${version}/Bibata.tar.gz";
    sha256 = "1g0vp4sgkq2kr3djbz2bi53iagrvj56jcy6m1isxd641ljjkcrvg";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/icons
    cp -a Bibata-* $out/share/icons

    # For backward compatibility:
    pushd $out/share/icons
    ln -s Bibata-Modern-Amber Bibata_Amber
    ln -s Bibata-Modern-Classic Bibata_Classic
    ln -s Bibata-Modern-Ice Bibata_Ice
    ln -s Bibata-Modern-Classic Bibata_Oil
    popd
  '';

  meta = with lib; {
    description = "Material Based Cursor";
    homepage = "https://github.com/ful1e5/Bibata_Cursor";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ rawkode pjones ];
  };
}
