{ pkgs
}:

{
  primary = {
    package = pkgs.overpass;
    name = "Overpass 12";
    ftname = "Overpass:style=Regular:size=12";
  };

  mono = {
    package = pkgs.hermit;
    name = "Hermit 10";
    ftname = "Hermit:pixelsize=10:style=Regular";
  };
}
