{ pkgs
}:

{
  primary = {
    package = pkgs.roboto;
    name = "Roboto Condensed 10";
    ftname = "Roboto Condensed:size=10";
    offset = 2; # Offset for Polybar.
  };

  mono = {
    package = pkgs.hermit;
    name = "Hermit 10";
    ftname = "Hermit:pixelsize=10:weight=normal";
    offset = 2;
  };

  font-awesome = {
    package = pkgs.font-awesome;
    name = "Font Awesome 5 Free 9";
    ftname = "Font Awesome 5 Free:style=Regular:pixelsize=9";
    offset = 2;
  };

  twemoji = {
    package = pkgs.twemoji-color-font;
    name = "Twemoji 10";
    ftname = "Twemoji:pixelsize=10";
    offset = 5;
  };

  weather = {
    package = pkgs.weather-icons;
    name = "Weather Icons 12";
    ftname = "Weather Icons:pixlesize=12";
    offset = 1;
  };
}
