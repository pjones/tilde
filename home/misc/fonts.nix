{ pkgs
}:

{
  primary = {
    package = pkgs.overpass;
    name = "Overpass 12";
    ftname = "Overpass:style=Regular:size=12";
    offset = 2; # Offset for Polybar.
  };

  polybar = {
    package = pkgs.overpass;
    name = "Overpass Semibold 10";
    ftname = "Overpass:style=Semibold:size=10";
    offset = 2;
  };

  mono = {
    package = pkgs.hermit;
    name = "Hermit 10";
    ftname = "Hermit:pixelsize=10:style=Regular";
    offset = 2;
  };

  font-awesome = {
    package = pkgs.font-awesome;
    name = "Font Awesome 6 Free";
    ftname = "Font Awesome 6 Free:style=Solid:pixelsize=9";
    offset = 2;
  };
}
