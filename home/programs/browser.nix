{ config
, pkgs
, lib
, ...
}:
let
  cfg = config.tilde.programs.browser;

  # MIME types that should be associated with a web browser:
  mimeTypes = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/unknown"
    "application/xhtml+xml"
    "text/html"
  ];

in
{
  options.tilde.programs.browser = {
    enable = lib.mkEnableOption "Web Browser Scripts";
  };

  config = lib.mkIf cfg.enable {
    tilde.programs.firefox.enable = true;

    home.file = {
      ".local/share/applications/browser.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Exec=browser %U
        Terminal=false
        Name=Browser
        Comment=Browser Wrapper
        GenericName=Web Browser
        MimeType=${lib.concatStringsSep ";" mimeTypes}
        Categories=Network;WebBrowser;
      '';
    };

    xdg.mimeApps = {
      enable = lib.mkDefault true;

      defaultApplications =
        builtins.listToAttrs
          (map
            (name: {
              inherit name;
              value = "browser.desktop";
            })
            mimeTypes);
    };
  };
}
