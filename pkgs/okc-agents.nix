{ stdenvNoCC
, fetchzip
, system
}:
let
  version = "0.1.1";

  mkurl = cpu:
    "https://github.com/DDoSolitary/okc-agents"
    + "/releases/download/v0.1.1/okc-agents-v${version}-${cpu}.zip";

  urls = {
    "x86_64-linux" = {
      url = mkurl "x86_64";
      sha256 = "0bmaq2k6bs57sdd3yvyfyl01gim253chff3dccyf42gpfxi3l74k";
    };

    "aarch64-linux" = {
      url = mkurl "aarch64";
      sha256 = "14151hslcj4pwa39sdi4fd8an8jck11rsrr7p7y8vdw7sba1ywxs";
    };
  };

in
stdenvNoCC.mkDerivation rec {
  inherit version;
  pname = "okc-agents";
  src = fetchzip (urls.${system} // { stripRoot = false; });
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    install -m 0555 okc-gpg $out/bin
    install -m 0555 okc-ssh-agent $out/bin
  '';

  meta = with stdenvNoCC.lib; {
    description = "A utility that makes OpenKeychain available in your Termux shell";
    homepage = "https://github.com/DDoSolitary/OkcAgent";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pjones ];
  };
}
