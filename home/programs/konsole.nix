{ pkgs
, config
, lib
, ...
}:
let
  fonts = import ../misc/fonts.nix { inherit pkgs; };
  consoleFont = lib.replaceStrings [ " " ] [ "," ] fonts.mono.name;

  konsolerc = pkgs.writeText "konsolerc" ''
    [Desktop Entry]
    DefaultProfile=main.profile

    [Favorite Profiles]
    Favorites=

    [KonsoleWindow]
    AllowMenuAccelerators=true
    RemoveWindowTitleBarAndFrame=false
    SaveGeometryOnExit=false
    ShowMenuBarByDefault=false
    ShowWindowTitleOnTitleBar=true

    [MainWindow]
    MenuBar=Disabled
    State=AAAA/wAAAAD9AAAAAAAAA9QAAALEAAAABAAAAAQAAAAIAAAACPwAAAABAAAAAgAAAAIAAAAWAG0AYQBpAG4AVABvAG8AbABCAGEAcgAAAAAA/////wAAAAAAAAAAAAAAHABzAGUAcwBzAGkAbwBuAFQAbwBvAGwAYgBhAHIAAAAAAP////8AAAAAAAAAAA==

    [SearchSettings]
    SearchRegExpression=true
  '';

  profile = pkgs.writeText "konsole.profile" ''
    [Appearance]
    ColorScheme=Sweet
    Font=${consoleFont},-1,5,50,0,0,0,0,0,Regular
    UseFontLineChararacters=true

    [Cursor Options]
    CursorShape=1

    [General]
    Command=${pkgs.pjones.tmuxrc}/bin/tmux-new-terminal
    LocalTabTitleFormat=%d %w
    Name=main
    Parent=FALLBACK/
    RemoteTabTitleFormat=%h
    SilenceSeconds=30

    [Interaction Options]
    AutoCopySelectedText=true
    CopyTextAsHTML=false
    MiddleClickPasteMode=1
    MouseWheelZoomEnabled=false
    OpenLinksByDirectClickEnabled=true

    [Scrolling]
    HistoryMode=1
    HistorySize=1000
    ScrollBarPosition=2

    [Terminal Features]
    BlinkingCursorEnabled=false
    FlowControlEnabled=false
    UrlHintsModifiers=100663296
  '';

in
{
  config = lib.mkIf config.tilde.xsession.enable {
    home.packages = [ pkgs.konsole ];
    home.file = {
      ".config/konsolerc".source = konsolerc;
      ".local/share/konsole/main.profile".source = profile;
      ".local/share/konsole/Sweet.colorscheme".source =
        "${pkgs.sweet-nova}/share/konsole/themes/sweet-nova/Sweet.colorscheme";
    };
  };
}
