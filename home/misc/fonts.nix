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
    name = "Font Awesome 5 Free 9";
    ftname = "Font Awesome 5 Free:style=Solid:pixelsize=9";
    offset = 2;
  };

  twemoji = {
    package = pkgs.twemoji-color-font;
    name = "Twitter Color Emoji 10";
    ftname = "Twitter Color Emoji:style=Regular:pixelsize=10";
    offset = 5;
  };

  weather = {
    package = pkgs.weather-icons;
    name = "Weather Icons 12";
    ftname = "Weather Icons:pixlesize=12";
    offset = 1;
  };
}
