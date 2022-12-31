{ stdenv
, polybar-scripts
, wrapPython
, dbus-python
, pygobject3
}:

stdenv.mkDerivation rec {
  inherit (polybar-scripts) version;
  pname = "player-mpris-tail";
  src = polybar-scripts;

  buildInputs = [ wrapPython ];
  pythonPath = [ dbus-python pygobject3 ];


  installPhase = ''
    mkdir -p $out/bin
    install -m 555 polybar-scripts/${pname}/${pname}.py $out/bin/${pname}
    wrapPythonProgramsIn $out/bin "$out $pythonPath"
  '';
}
