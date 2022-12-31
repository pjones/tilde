{ pkgs }:

rec {
  # Color names:
  black = "#282a36";
  darkblack = "#0d101d";
  white = "#f8f8f2";
  gray = "#44475a";
  green = "#50fa7b";
  red = "#ff5555";
  orange = "#ffb86c";
  yellow = "#f1fa8c";
  purple = "#bd93f9";
  darkpurple = "#735a97";
  pink = "#ff79c6";
  blue = "#bd93f9";
  cyan = "#8be9fd";

  # Symbolic names:
  background = black;
  background-offset = darkblack;
  foreground = white;
  foreground-dim = gray;
  okay = green;
  warn = orange;
  fail = red;
  alert = cyan;
  active = darkpurple;

  # GTK theme:
  theme = {
    package = pkgs.dracula-theme;
    name = "Dracula";
  };
}
